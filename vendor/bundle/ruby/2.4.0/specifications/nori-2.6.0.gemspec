# -*- encoding: utf-8 -*-
# stub: nori 2.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "nori".freeze
  s.version = "2.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze, "John Nunemaker".freeze, "Wynn Netherland".freeze]
  s.date = "2015-05-07"
  s.description = "XML to Hash translator".freeze
  s.email = "me@rubiii.com".freeze
  s.homepage = "https://github.com/savonrb/nori".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubyforge_project = "nori".freeze
  s.rubygems_version = "2.6.11".freeze
  s.summary = "XML to Hash translator".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<nokogiri>.freeze, [">= 1.4.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.12"])
    else
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<nokogiri>.freeze, [">= 1.4.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.12"])
    end
  else
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<nokogiri>.freeze, [">= 1.4.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.12"])
  end
end
