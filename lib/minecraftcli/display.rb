require "time"

module Minecraftcli
  module Display
    RESET  = "\e[0m"
    BOLD   = "\e[1m"
    GREEN  = "\e[32m"
    CYAN   = "\e[36m"
    YELLOW = "\e[33m"
    DIM    = "\e[2m"
    WHITE  = "\e[97m"

    INNER_WIDTH = 38

    # Each row is exactly 16 visible chars. Color applied after, so widths are safe.
    CREEPER_ROWS = [
      "████████████████",
      "████████████████",
      "████    ████    ",
      "████    ████    ",
      "██████    ██████",
      "██  ██    ██  ██",
      "██    ████    ██",
      "████████████████",
    ].freeze

    # Each row is exactly 5 visible chars.
    SWORD_ROWS = [
      "  ▲  ",
      " ███ ",
      " ███ ",
      " ███ ",
      "═════",
      "  █  ",
      "  █  ",
    ].freeze

    CAPE_NAMES = {
      "953cac8b779fe41383e675ee2b86071a71658f2180f56fbce8aa315ea70e2ed6" => "Minecon 2011 Cape",
      "a2e8d97ec79100e90a75d369d1b3ba81273c4f82bc1b737e934eed4a854be1b6" => "Minecon 2012 Cape",
      "153b1a0dfcbae953cdeb6f2c2bf6bf79943239b1372780da44bcbb29273131da" => "Minecon 2013 Cape",
      "b0cc08840700447322d953a02b965f1d65a13a603bf64b17c803c21446fe1635" => "Minecon 2015 Cape",
      "e7dfea16dc83c97df01a12fabbd1216359c0cd0ea42f9999b6e97c584963e980" => "Minecon 2016 Cape",
      "5786fe99be377dfb6858859f926c4dbc995751e91cee373468c5fbf4865e7151" => "Mojang Employee Cape",
      "2340c0e03dd24a11b15a8b33c2a7e9e32abb2051b2481d0ba7defd635ca7a933" => "Migrator Cape",
      "99aba02ef05ec6aa4d42db8ee43796d6cd50e4b2954ab29f0caeb85f96bf52a1" => "Founder's Cape",
      "5c29410057e32abec02d870ecb52ec25fb45ea81e785a7854ae8429d7236ca26" => "Mojang Office Cape",
      "17912790ff164b93196f08ba71d0e62129304776d0f347334f8a6eae509f8a56" => "Realms MapMaker Cape",
      "cd9d82ab17fd92022dbd4a86cde4c382a7540e117fae7b9a2853658505a80625" => "15th Anniversary Cape",
      "afd553b39358a24edfe3b8a9a939fa5fa4faa4d9a9c3d6af8eafb377fa05c2bb" => "Cherry Blossom Cape",
      "cb40a92e32b57fd732a00fc325e7afb00a7ca74936ad50d8e860152e482cfbde" => "Purple Heart Cape",
      "28de4a81688ad18b49e735a273e086c18f1e3966956123ccb574034c06f5d336" => "Pan Cape",
      "dbc21e222528e30dc88445314f7be6ff12d3aeebc3c192054fba7e3b3f8c77b1" => "Menace Cape",
      "a3f6e4f14801f3ea55e3d95b9b4ef3b5e8802d947f669de93d6ec4b9354a436b" => "Zombie Horse Cape",
      "7658c5025c77cfac7574aab3af94a46a8886e3b7722a895255fbf22ab8652434" => "Minecraft Experience Cape",
      "569b7f2a1d00d26f30efe3f9ab9ac817b1e6d35f4f3cfb0324ef2d328223d350" => "Follower's Cape",
      "308b32a9e303155a0b4262f9e5483ad4a22e3412e84fe8385a0bdd73dc41fa89" => "Yearn Cape",
      "5ec930cdd2629c8771655c60eebeb867b4b6559b0e6d3bc71c40c96347fa03f0" => "Common Cape",
      "f9a76537647989f9a0b6d001e320dac591c359e9e61a31f4ce11c88f207f0ad4" => "Vanilla Cape",
      "1de21419009db483900da6298a1e6cbf9f1bc1523a0dcdc16263fab150693edd" => "Home Cape",
      "5e6f3193e74cd16cdd6637d9bae5484e3a37ff2a14c2d157c659a07810b1bdca" => "Copper Cape",
    }.freeze

    BANNER_ART = [
      "▄▄▄▄  ▄ ▄▄▄▄  ▗▞▀▚▖▗▞▀▘ ▄▄▄ ▗▞▀▜▌▗▞▀▀▘■  ▗▞▀▘█ ▄ ",
      "█ █ █ ▄ █   █ ▐▛▀▀▘▝▚▄▖█    ▝▚▄▟▌▐▌▗▄▟▙▄▖▝▚▄▖█ ▄ ",
      "█   █ █ █   █ ▝▚▄▄▖    █         ▐▛▀▘▐▌      █ █ ",
      "      █                          ▐▌  ▐▌      █ █ ",
      "                                     ▐▌          ",
    ].freeze

    def self.player(username, uuid, textures, name_history, cape_history, name_change_count, socials, source_label, source_log)
      puts
      puts "#{BOLD}#{GREEN}#{username}#{RESET}"
      puts separator

      formatted_uuid = format_uuid(uuid)
      puts "#{BOLD}UUID#{RESET}  #{CYAN}#{formatted_uuid}#{RESET}"
      puts

      section "Capes" do
        active_cape_url = textures.dig("CAPE", "url")
        active_cape_name = active_cape_url ? cape_name(active_cape_url) : nil
        puts "  #{GREEN}Equipped:#{RESET} #{active_cape_name || "#{DIM}None#{RESET}"}"

        if cape_history.empty?
          puts "  #{DIM}Known capes unavailable#{RESET}"
        else
          puts "  #{GREEN}All known official capes:#{RESET}"
          if cape_history.first.is_a?(Hash) && cape_history.first["source"] == "namemc"
            cape_history.each do |entry|
              label = entry["name"] || "Cape #{entry["slug"]}"
              puts "  #{YELLOW}-#{RESET} #{GREEN}#{label}#{RESET}"
            end
          else
            normalized_urls = {}
            cape_entries = cape_history
              .sort_by { |entry| -(entry["time"] || 0).to_i }
              .filter_map do |entry|
                image_url = entry["imageUrl"].to_s
                next if image_url.empty?
                next if normalized_urls.key?(image_url)

                normalized_urls[image_url] = true
                {
                  image_url: image_url,
                  seen_at: entry["time"],
                }
              end

            if cape_entries.empty?
              puts "  #{DIM}Known capes unavailable#{RESET}"
            else
              cape_entries.each do |entry|
                timestamp = entry[:seen_at]
                date = timestamp ? Time.at(timestamp.to_i).utc.strftime("%Y-%m-%d") : "unknown date"
                short_hash = entry[:image_url].split("/").last.to_s[0..9]
                puts "  #{YELLOW}-#{RESET} #{GREEN}Cape #{short_hash}…#{RESET}  #{DIM}#{date}#{RESET}"
              end
            end
          end
        end
      end

      section_name = name_change_count ? "Name History (#{name_change_count}NC)" : "Name History"
      section section_name do
        if name_history.nil?
          puts "  #{DIM}Name history unavailable#{RESET}"
        elsif name_history.empty?
          puts "  #{DIM}No history found#{RESET}"
        else
          rank_width = 2
          name_width = 16
          date_width = 10
          status_width = 7

          puts "  #{DIM}┌────┬──────────────────┬────────────┬─────────┐#{RESET}"
          header_rank = "#".rjust(rank_width)
          header_name = "Name".ljust(name_width)
          header_date = "Changed".ljust(date_width)
          header_status = "Status".ljust(status_width)
          puts "  #{DIM}│#{RESET} #{BOLD}#{header_rank}#{RESET} #{DIM}│#{RESET} #{BOLD}#{header_name}#{RESET} #{DIM}│#{RESET} #{BOLD}#{header_date}#{RESET} #{DIM}│#{RESET} #{BOLD}#{header_status}#{RESET} #{DIM}│#{RESET}"
          puts "  #{DIM}├────┼──────────────────┼────────────┼─────────┤#{RESET}"

          name_history.each_with_index do |entry, i|
            hidden = entry["hidden"] || false
            name = if hidden
                     "[hidden]"
                   else
                     entry["username"] || entry["name"] || "unknown"
                   end
            changed_at = entry["changed_at"]
            rank = entry["rank"]

            if changed_at
              ts    = Time.parse(changed_at.to_s)
              label = ts.strftime("%Y-%m-%d")
            else
              label = (rank == 1 || i == name_history.length - 1) ? "original" : "unknown date"
            end

            marker = if entry["current"] == true
                       "current"
                     elsif entry["current"] == false
                       "-"
                     else
                       i == name_history.length - 1 ? "current" : "-"
                     end

            rank_display = (rank || "?").to_s.rjust(rank_width)
            name_display = truncate_text(name.to_s, name_width).ljust(name_width)
            date_display = truncate_text(label, date_width).ljust(date_width)
            status_display = marker.ljust(status_width)
            status_colored = marker == "current" ? "#{GREEN}#{status_display}#{RESET}" : "#{DIM}#{status_display}#{RESET}"

            puts "  #{DIM}│#{RESET} #{YELLOW}#{rank_display}#{RESET} #{DIM}│#{RESET} #{GREEN}#{name_display}#{RESET} #{DIM}│#{RESET} #{CYAN}#{date_display}#{RESET} #{DIM}│#{RESET} #{status_colored} #{DIM}│#{RESET}"
          end

          puts "  #{DIM}└────┴──────────────────┴────────────┴─────────┘#{RESET}"
        end
      end

      section "Socials" do
        if socials.nil? || socials.empty?
          puts "  #{DIM}No socials listed#{RESET}"
        else
          socials.each do |social|
            service = social["service"] || "Website"
            url = social["url"] || "-"
            puts "  #{YELLOW}-#{RESET} #{GREEN}#{service}:#{RESET} #{CYAN}#{url}#{RESET}"
          end
        end
      end

      puts separator
      puts
    end

    def self.banner
      puts
      BANNER_ART.each { |line| puts "  #{GREEN}#{line}#{RESET}" }
      art_width = BANNER_ART.map(&:length).max
      puts "  #{DIM}#{center_text("Account & Profile Lookup Tool", art_width)}#{RESET}"
      puts "  #{YELLOW}#{center_text("v 0 . 1 . 0", art_width)}#{RESET}"
      puts
      puts "  #{DIM}Type #{RESET}#{GREEN}help#{RESET}#{DIM} to see available commands#{RESET}"
      puts
    end

    def self.help
      puts
      puts "  #{BOLD}Commands#{RESET}"
      puts "  #{DIM}#{"─" * 36}#{RESET}"
      puts "  #{GREEN}lookup <username>#{RESET}   #{DIM}Look up a Minecraft player#{RESET}"
      puts "  #{GREEN}clear#{RESET}               #{DIM}Clear the screen#{RESET}"
      puts "  #{GREEN}exit#{RESET}                #{DIM}Quit MinecraftCLI#{RESET}"
      puts
    end

    def self.goodbye
      puts
      puts "#{GREEN}▄▄▄ ▗▞▀▚▖▗▞▀▚▖    ▄   ▄ ▗▞▀▜▌#{RESET}"
      puts "#{GREEN}▀▄▄  ▐▛▀▀▘▐▛▀▀▘    █   █ ▝▚▄▟▌#{RESET}"
      puts "#{GREEN}▄▄▄▀ ▝▚▄▄▖▝▚▄▄▖     ▀▀▀█      #{RESET}"
      puts "#{GREEN}                   ▄   █      #{RESET}"
      puts "#{GREEN}                    ▀▀▀       #{RESET}"
      puts
    end

    def self.error(message)
      puts "\n  #{BOLD}\e[31m✖#{RESET}  #{message}\n"
    end

    private

    def self.banner_row(content, color = "")
      "  #{GREEN}║#{RESET}#{color}#{content}#{RESET}#{GREEN}║#{RESET}"
    end

    def self.center_text(text, width)
      lpad = (width - text.length) / 2
      rpad = width - text.length - lpad
      "#{" " * lpad}#{text}#{" " * rpad}"
    end

    def self.cape_name(url)
      hash = url.to_s.split("/").last
      CAPE_NAMES[hash] || "Unknown Cape (#{hash[0..7]}…)"
    end

    def self.section(title)
      puts "#{BOLD}#{title}#{RESET}"
      yield
      puts
    end

    def self.separator
      "#{DIM}#{"─" * 40}#{RESET}"
    end

    def self.format_uuid(raw)
      return raw if raw.length != 32

      "#{raw[0..7]}-#{raw[8..11]}-#{raw[12..15]}-#{raw[16..19]}-#{raw[20..]}"
    end

    def self.truncate_text(text, max_len)
      return text if text.length <= max_len

      "#{text[0...(max_len - 1)]}…"
    end
  end
end
