Gem::Specification.new do |spec|
  spec.name          = "minecraftcli"
  spec.version       = "0.1.0"
  spec.authors       = ["johncastro"]
  spec.summary       = "CLI tool to look up Minecraft account info"
  spec.description   = "Look up a Minecraft player's UUID, capes, and name history from the command line"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb", "bin/*"]
  spec.bindir        = "bin"
  spec.executables   = ["minecraftcli"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"
  spec.add_dependency "selenium-webdriver"
end
