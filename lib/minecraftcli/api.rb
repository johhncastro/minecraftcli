require "net/http"
require "json"
require "base64"
require "uri"
require "cgi"
require "tmpdir"
require "fileutils"

module Minecraftcli
  module API
    MOJANG_API   = "https://api.mojang.com"
    SESSION_API  = "https://sessionserver.mojang.com"
    ASHCON_API   = "https://api.ashcon.app/mojang/v2/user"
    CAPES_API    = "https://api.capes.dev"
    NAMEMC_URL   = "https://namemc.com"
    USER_AGENT   = "minecraftcli/0.1.0"

    def self.get(url, headers = {})
      uri = URI.parse(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.open_timeout = 5
        http.read_timeout = 10
        http.get(uri.request_uri, headers)
      end
      return nil if response.code == "204" || response.body.nil? || response.body.empty?
      return nil unless response.code.start_with?("2")

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise "Request timed out. Check your internet connection."
    rescue SocketError
      raise "Could not reach Mojang servers. Check your internet connection."
    rescue JSON::ParserError
      nil
    end

    def self.uuid_for(username)
      data = get("#{MOJANG_API}/users/profiles/minecraft/#{URI.encode_uri_component(username)}")
      return nil if data.nil?

      data["id"]
    end

    def self.profile(uuid)
      get("#{SESSION_API}/session/minecraft/profile/#{uuid}")
    end

    def self.textures(profile)
      encoded = profile.dig("properties")
                       &.find { |p| p["name"] == "textures" }
                       &.dig("value")
      return {} if encoded.nil?

      decoded = Base64.decode64(encoded)
      JSON.parse(decoded)["textures"] || {}
    rescue JSON::ParserError
      {}
    end

    def self.name_history(username)
      data = get("#{ASHCON_API}/#{URI.encode_uri_component(username)}")
      return nil if data.nil?

      data["username_history"]
    rescue => _e
      nil
    end

    def self.cape_history(username)
      data = get(
        "#{CAPES_API}/history/#{URI.encode_uri_component(username)}/minecraft",
        { "User-Agent" => USER_AGENT }
      )
      return [] if data.nil?

      history = data["history"]
      return [] unless history.is_a?(Array)

      history
    rescue => _e
      []
    end

    def self.namemc_profile_attempt(username)
      profile_url = "#{NAMEMC_URL}/profile/#{URI.encode_uri_component(username)}"

      browser_response = get_html_with_browser(profile_url)
      if browser_response[:ok]
        parsed = parse_namemc_profile(browser_response[:body].to_s)
        if parsed[:ok]
          return {
            ok: true,
            log: "NameMC success via browser (aliases=#{parsed[:name_history].length}, capes=#{parsed[:capes].length}, nc=#{parsed[:name_change_count] || "?"})",
            data: {
              aliases: parsed[:name_history],
              capes: parsed[:capes],
              name_change_count: parsed[:name_change_count],
              socials: parsed[:socials],
            },
          }
        end
      end

      response = get_html_with_metadata(profile_url)
      if response[:ok] && response[:status].to_s.start_with?("2")
        parsed = parse_namemc_profile(response[:body].to_s)
        if parsed[:ok]
          return {
            ok: true,
            log: "NameMC success via http (status #{response[:status]}, aliases=#{parsed[:name_history].length}, capes=#{parsed[:capes].length}, nc=#{parsed[:name_change_count] || "?"})",
            data: {
              aliases: parsed[:name_history],
              capes: parsed[:capes],
              name_change_count: parsed[:name_change_count],
              socials: parsed[:socials],
            },
          }
        end
      end

      failure_parts = []
      unless browser_response[:ok]
        failure_parts << "browser failed: #{browser_response[:error]}"
      else
        failure_parts << "browser parsed no data"
      end

      if response[:ok]
        if response[:status].to_s.start_with?("2")
          failure_parts << "http parsed no data (status #{response[:status]})"
        else
          failure_parts << "http status #{response[:status]}"
        end
      else
        failure_parts << "http failed: #{response[:error]}"
      end

      failure_result(failure_parts.join("; "))
    rescue => e
      failure_result("#{e.class}: #{e.message}")
    end

    def self.get_html(url, headers = {})
      result = get_html_with_metadata(url, headers)
      return nil unless result[:ok] && result[:status].start_with?("2")

      result[:body]
    end

    def self.get_html_with_metadata(url, headers = {})
      uri = URI.parse(url)
      request_headers = {
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      }.merge(headers)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.open_timeout = 5
        http.read_timeout = 10
        http.get(uri.request_uri, request_headers)
      end

      {
        ok: true,
        status: response.code.to_s,
        body: response.body.to_s,
      }
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      { ok: false, status: nil, body: nil, error: "timeout (#{e.class})" }
    rescue SocketError => e
      { ok: false, status: nil, body: nil, error: "socket error (#{e.class})" }
    rescue => e
      { ok: false, status: nil, body: nil, error: "#{e.class}: #{e.message}" }
    end

    def self.get_html_with_browser(url)
      begin
        require "selenium-webdriver"
      rescue LoadError
        return {
          ok: false,
          body: nil,
          error: "selenium-webdriver gem not installed (run: bundle add selenium-webdriver)",
        }
      end

      profile_dir = Dir.mktmpdir("minecraftcli-chrome-")
      options = Selenium::WebDriver::Chrome::Options.new
      options.page_load_strategy = :eager
      options.add_argument("--headless=new")
      options.add_argument("--disable-gpu")
      options.add_argument("--no-sandbox")
      options.add_argument("--window-size=1366,900")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--user-data-dir=#{profile_dir}")
      options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

      begin
        driver = Selenium::WebDriver.for(:chrome, options: options)
        driver.manage.timeouts.page_load = 45
        begin
          driver.navigate.to(url)
        rescue Selenium::WebDriver::Error::TimeoutError
          # NameMC can stall on anti-bot checks; continue and inspect whatever HTML was rendered.
        end

        wait = Selenium::WebDriver::Wait.new(timeout: 15)
        wait.until { !driver.page_source.to_s.strip.empty? }

        {
          ok: true,
          body: driver.page_source.to_s,
          error: nil,
        }
      ensure
        driver&.quit
        FileUtils.remove_entry(profile_dir) if profile_dir && Dir.exist?(profile_dir)
      end
    rescue => e
      {
        ok: false,
        body: nil,
        error: "#{e.class}: #{e.message}",
      }
    end

    def self.parse_namemc_profile(html)
      return { ok: false, error: "empty response body" } if html.nil? || html.empty?
      return { ok: false, error: "cloudflare challenge page detected" } if html.include?("Just a moment...") || html.include?("__cf_chl")

      history_data = extract_namemc_name_history(html)
      aliases = history_data[:entries]
      capes = extract_namemc_capes(html)
      socials = extract_namemc_socials(html)
      return { ok: false, error: "profile parsed but no aliases/capes found" } if aliases.empty? && capes.empty?

      {
        ok: true,
        name_history: aliases,
        name_change_count: history_data[:name_change_count],
        capes: capes,
        socials: socials,
      }
    end

    def self.extract_namemc_aliases(html)
      names = html.scan(/href="\/search\?q=([^"]+)"/i)
                  .flatten
                  .map { |raw| CGI.unescapeHTML(raw.to_s) }
                  .map { |raw| URI.decode_www_form_component(raw) rescue raw }
                  .map(&:strip)
                  .reject(&:empty?)
                  .uniq

      names.map { |name| { "username" => name } }
    end

    def self.extract_namemc_name_history(html)
      rows = html.scan(/<tr>\s*<td[^>]*fw-bold[^>]*>(\d+)<\/td>(.*?)<\/tr>/m)
      return { entries: extract_namemc_aliases(html), name_change_count: nil } if rows.empty?

      ranks = []
      entries = rows.map do |rank_text, row_html|
        rank = rank_text.to_i
        ranks << rank

        raw_name = row_html[/href="\/search\?q=([^"]+)"/i, 1]
        name = if raw_name
                 decoded = CGI.unescapeHTML(raw_name.to_s)
                 URI.decode_www_form_component(decoded) rescue decoded
               end

        changed_at = row_html[/<time\s+datetime="([^"]+)"/i, 1]

        {
          "username" => (name && !name.empty? ? name.strip : nil),
          "changed_at" => changed_at,
          "current" => false,
          "hidden" => name.nil? || name.strip.empty?,
          "rank" => rank,
        }
      end

      max_rank = ranks.max
      entries.each { |entry| entry["current"] = (entry["rank"] == max_rank) }

      { entries: entries, name_change_count: max_rank }
    end

    def self.extract_namemc_capes(html)
      seen = {}
      capes = []

      anchors = html.scan(/<a\b[^>]*href="\/cape\/[^"]+"[^>]*>/i)
      anchors.each do |anchor|
        slug = anchor[/href="\/cape\/([^"]+)"/i, 1]
        slug = CGI.unescapeHTML(slug.to_s).strip
        next if slug.empty? || seen.key?(slug)
        seen[slug] = true

        title = anchor[/\btitle="([^"]+)"/i, 1]
        title = CGI.unescapeHTML(title.to_s).strip unless title.nil?
        title = nil if title&.empty?

        capes << {
          "slug" => slug,
          "name" => (title || namemc_cape_name_from_slug(slug)),
          "source" => "namemc",
        }
      end

      capes
    end

    def self.namemc_cape_name_from_slug(slug)
      return nil if slug.nil? || slug.empty?

      human = slug.to_s.tr("-", " ").strip
      return nil if human.empty?
      return nil if human.match?(/\A[0-9a-f]{16,64}\z/i)

      human.split.map(&:capitalize).join(" ")
    end

    def self.extract_namemc_socials(html)
      info_block = html[/<strong>\s*Information\s*<\/strong>(.*?)<\/div>\s*<\/div>/mi, 1]
      return [] if info_block.nil? || info_block.empty?

      socials = []
      seen = {}

      info_block.scan(/<a\b[^>]*href="([^"]+)"[^>]*>(.*?)<\/a>/mi).each do |href, anchor_html|
        next unless href.start_with?("http://", "https://")

        uri = URI.parse(href) rescue nil
        next if uri.nil? || uri.host.nil?

        host = uri.host.downcase
        next if host.include?("namemc.com")

        service = anchor_html[/\/img\/service\/([a-z0-9_-]+)\.svg/i, 1]
        service ||= host.sub(/\Awww\./, "").split(".").first
        service_label = service.to_s.tr("_-", " ").split.map(&:capitalize).join(" ")
        service_label = "Website" if service_label.empty?

        key = "#{service_label}|#{href}"
        next if seen[key]
        seen[key] = true

        socials << {
          "service" => service_label,
          "url" => href,
        }
      end

      socials
    end

    def self.failure_result(reason)
      {
        ok: false,
        log: "NameMC failed: #{reason}. Falling back to Mojang + fallback APIs.",
        data: nil,
      }
    end
  end
end
