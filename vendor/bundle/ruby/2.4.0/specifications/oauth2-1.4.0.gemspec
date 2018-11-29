# -*- encoding: utf-8 -*-
# stub: oauth2 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth2".freeze
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Erik Michaels-Ober".freeze]
  s.date = "2017-06-09"
  s.description = "A Ruby wrapper for the OAuth 2.0 protocol built with a similar style to the original OAuth spec.".freeze
  s.email = ["michael@intridea.com".freeze, "sferik@gmail.com".freeze]
  s.homepage = "http://github.com/intridea/oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.11".freeze
  s.summary = "A Ruby wrapper for the OAuth 2.0 protocol.".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>.freeze, ["< 0.13", ">= 0.8"])
      s.add_runtime_dependency(%q<jwt>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.3"])
      s.add_runtime_dependency(%q<multi_xml>.freeze, ["~> 0.5"])
      s.add_runtime_dependency(%q<rack>.freeze, ["< 3", ">= 1.2"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0"])
    else
      s.add_dependency(%q<faraday>.freeze, ["< 0.13", ">= 0.8"])
      s.add_dependency(%q<jwt>.freeze, ["~> 1.0"])
      s.add_dependency(%q<multi_json>.freeze, ["~> 1.3"])
      s.add_dependency(%q<multi_xml>.freeze, ["~> 0.5"])
      s.add_dependency(%q<rack>.freeze, ["< 3", ">= 1.2"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<faraday>.freeze, ["< 0.13", ">= 0.8"])
    s.add_dependency(%q<jwt>.freeze, ["~> 1.0"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.3"])
    s.add_dependency(%q<multi_xml>.freeze, ["~> 0.5"])
    s.add_dependency(%q<rack>.freeze, ["< 3", ">= 1.2"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
  end
end
