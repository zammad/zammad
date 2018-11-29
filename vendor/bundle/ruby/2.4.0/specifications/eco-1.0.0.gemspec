# -*- encoding: utf-8 -*-
# stub: eco 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "eco".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Stephenson".freeze]
  s.date = "2011-06-04"
  s.description = "    Ruby Eco is a bridge to the official JavaScript Eco compiler.\n".freeze
  s.email = "sstephenson@gmail.com".freeze
  s.homepage = "https://github.com/sstephenson/ruby-eco".freeze
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Ruby Eco Compiler (Embedded CoffeeScript templates)".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<coffee-script>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<eco-source>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<execjs>.freeze, [">= 0"])
    else
      s.add_dependency(%q<coffee-script>.freeze, [">= 0"])
      s.add_dependency(%q<eco-source>.freeze, [">= 0"])
      s.add_dependency(%q<execjs>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<coffee-script>.freeze, [">= 0"])
    s.add_dependency(%q<eco-source>.freeze, [">= 0"])
    s.add_dependency(%q<execjs>.freeze, [">= 0"])
  end
end
