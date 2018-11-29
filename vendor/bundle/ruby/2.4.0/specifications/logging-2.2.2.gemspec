# -*- encoding: utf-8 -*-
# stub: logging 2.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "logging".freeze
  s.version = "2.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Pease".freeze]
  s.date = "2017-04-11"
  s.description = "**Logging** is a flexible logging library for use in Ruby programs based on the\ndesign of Java's log4j library. It features a hierarchical logging system,\ncustom level names, multiple output destinations per log event, custom\nformatting, and more.".freeze
  s.email = "tim.pease@gmail.com".freeze
  s.extra_rdoc_files = ["History.txt".freeze]
  s.files = ["History.txt".freeze]
  s.homepage = "http://rubygems.org/gems/logging".freeze
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubyforge_project = "logging".freeze
  s.rubygems_version = "2.6.11".freeze
  s.summary = "A flexible and extendable logging library for Ruby".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
      s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<bones-git>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<bones>.freeze, [">= 3.8.4"])
    else
      s.add_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
      s.add_dependency(%q<multi_json>.freeze, ["~> 1.10"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.1"])
      s.add_dependency(%q<bones-git>.freeze, ["~> 1.3"])
      s.add_dependency(%q<bones>.freeze, [">= 3.8.4"])
    end
  else
    s.add_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.10"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.1"])
    s.add_dependency(%q<bones-git>.freeze, ["~> 1.3"])
    s.add_dependency(%q<bones>.freeze, [">= 3.8.4"])
  end
end
