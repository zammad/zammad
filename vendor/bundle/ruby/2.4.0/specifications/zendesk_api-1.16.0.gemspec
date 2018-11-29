# -*- encoding: utf-8 -*-
# stub: zendesk_api 1.16.0 ruby lib

Gem::Specification.new do |s|
  s.name = "zendesk_api".freeze
  s.version = "1.16.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Davidovitz".freeze, "Michael Grosser".freeze]
  s.date = "2017-11-12"
  s.description = "Ruby wrapper for the REST API at https://www.zendesk.com. Documentation at https://developer.zendesk.com.".freeze
  s.email = ["support@zendesk.com".freeze]
  s.homepage = "https://developer.zendesk.com".freeze
  s.licenses = ["Apache License Version 2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Zendesk REST API Client".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>.freeze, ["~> 0.9"])
      s.add_runtime_dependency(%q<hashie>.freeze, ["< 4.0.0", ">= 3.5.2"])
      s.add_runtime_dependency(%q<inflection>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<mime-types>.freeze, [">= 0"])
    else
      s.add_dependency(%q<faraday>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hashie>.freeze, ["< 4.0.0", ">= 3.5.2"])
      s.add_dependency(%q<inflection>.freeze, [">= 0"])
      s.add_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
      s.add_dependency(%q<mime-types>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<faraday>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hashie>.freeze, ["< 4.0.0", ">= 3.5.2"])
    s.add_dependency(%q<inflection>.freeze, [">= 0"])
    s.add_dependency(%q<multipart-post>.freeze, ["~> 2.0"])
    s.add_dependency(%q<mime-types>.freeze, [">= 0"])
  end
end
