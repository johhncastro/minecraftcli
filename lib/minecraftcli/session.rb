require "readline"

module Minecraftcli
  class Session
    PROMPT = "#{Display::GREEN}⛏ #{Display::RESET} #{Display::BOLD}>#{Display::RESET} "

    COMMANDS = [
      ["lookup <username>", "Look up a Minecraft player's profile"],
      ["help",              "Show this command list"],
      ["clear",             "Clear the screen"],
      ["exit",              "Quit MinecraftCLI"],
    ].freeze

    def self.start
      Display.banner
      Readline.completion_proc = proc { [] }

      loop do
        input = Readline.readline(PROMPT, true)

        if input.nil?
          Display.goodbye
          break
        end

        input = input.strip
        Readline::HISTORY.pop if input.empty?
        next if input.empty?

        cmd, arg = input.split(" ", 2)

        case cmd.downcase
        when "lookup", "user"
          if arg.nil? || arg.strip.empty?
            Display.error("Usage: lookup <username>")
          else
            Minecraftcli.lookup(arg.strip)
          end
        when "help"
          Display.help
        when "clear"
          print "\e[H\e[2J"
          Display.banner
        when "exit", "quit", "q"
          Display.goodbye
          break
        else
          Display.error("Unknown command '#{cmd}'  —  type help to see available commands")
        end
      end
    end
  end
end
