require_relative "minecraftcli/api"
require_relative "minecraftcli/display"

module Minecraftcli
  def self.lookup(username)
    uuid = API.uuid_for(username)

    if uuid.nil?
      Display.error("Player '#{username}' not found.")
      exit 1
    end

    profile      = API.profile(uuid)
    textures     = profile ? API.textures(profile) : {}
    namemc_attempt = API.namemc_profile_attempt(username)

    if namemc_attempt[:ok]
      name_history = namemc_attempt.dig(:data, :aliases)
      cape_history = namemc_attempt.dig(:data, :capes)
      name_change_count = namemc_attempt.dig(:data, :name_change_count)
      socials = namemc_attempt.dig(:data, :socials) || []
      source_label = "NameMC"
    else
      name_history = API.name_history(username)
      cape_history = API.cape_history(username)
      name_change_count = name_history.is_a?(Array) && name_history.length > 1 ? (name_history.length - 1) : nil
      socials = []
      source_label = "Mojang + fallback APIs"
    end

    Display.player(username, uuid, textures, name_history, cape_history, name_change_count, socials, source_label, namemc_attempt[:log])
  end
end
