# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nori/version"

Gem::Specification.new do |s|
  s.name        = "nori"
  s.version     = Nori::VERSION
  s.authors     = ["Daniel Harrington", "John Nunemaker", "Wynn Netherland"]
  s.email       = "me@rubiii.com"
  s.homepage    = "https://github.com/savonrb/nori"
  s.summary     = "XML to Hash translator"
  s.description = s.summary
  s.required_ruby_version = '>= 1.9.2'

  s.rubyforge_project = "nori"
  s.license = "MIT"

  s.add_development_dependency "rake",     "~> 10.0"
  s.add_development_dependency "nokogiri", ">= 1.4.0"
  s.add_development_dependency "rspec",    "~> 2.12"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
