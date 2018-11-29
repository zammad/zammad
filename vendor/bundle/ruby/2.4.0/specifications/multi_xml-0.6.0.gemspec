# -*- encoding: utf-8 -*-
# stub: multi_xml 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "multi_xml".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Erik Michaels-Ober".freeze]
  s.date = "2016-12-06"
  s.description = "Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.".freeze
  s.email = "sferik@gmail.com".freeze
  s.homepage = "https://github.com/sferik/multi_xml".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.11".freeze
  s.summary = "A generic swappable back-end for XML parsing".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
  end
end
