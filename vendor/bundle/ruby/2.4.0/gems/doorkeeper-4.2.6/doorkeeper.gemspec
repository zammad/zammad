$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "doorkeeper/version"

Gem::Specification.new do |s|
  s.name        = "doorkeeper"
  s.version     = Doorkeeper::VERSION
  s.authors     = ["Felipe Elias Philipp", "Tute Costa", "Jon Moss"]
  s.email       = %w(me@jonathanmoss.me)
  s.homepage    = "https://github.com/doorkeeper-gem/doorkeeper"
  s.summary     = "OAuth 2 provider for Rails and Grape"
  s.description = "Doorkeeper is an OAuth 2 provider for Rails and Grape."
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "railties", ">= 4.2"
  s.required_ruby_version = ">= 2.1"

  s.add_development_dependency "capybara"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "database_cleaner", "~> 1.5.3"
  s.add_development_dependency "factory_girl", "~> 4.7.0"
  s.add_development_dependency "generator_spec", "~> 0.9.3"
  s.add_development_dependency "rake", ">= 11.3.0"
  s.add_development_dependency "rspec-rails"
end
