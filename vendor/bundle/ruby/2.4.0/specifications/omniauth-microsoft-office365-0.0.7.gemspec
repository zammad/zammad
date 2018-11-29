# -*- encoding: utf-8 -*-
# stub: omniauth-microsoft-office365 0.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-microsoft-office365".freeze
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Marcin Urba\u0144ski".freeze]
  s.date = "2016-05-16"
  s.description = "OmniAuth provider for Microsoft Office365".freeze
  s.email = ["marcin@urbanski.vdl.pl".freeze]
  s.homepage = "https://github.com/murbanski/omniauth-microsoft-office365".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "OmniAuth provider for Microsoft Office365".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<omniauth>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<omniauth-oauth2>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_development_dependency(%q<rake>.freeze, [">= 11.1.2"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 3.4.0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0.10.3"])
    else
      s.add_dependency(%q<omniauth>.freeze, [">= 0"])
      s.add_dependency(%q<omniauth-oauth2>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_dependency(%q<rake>.freeze, [">= 11.1.2"])
      s.add_dependency(%q<rspec>.freeze, [">= 3.4.0"])
      s.add_dependency(%q<pry>.freeze, [">= 0.10.3"])
    end
  else
    s.add_dependency(%q<omniauth>.freeze, [">= 0"])
    s.add_dependency(%q<omniauth-oauth2>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
    s.add_dependency(%q<rake>.freeze, [">= 11.1.2"])
    s.add_dependency(%q<rspec>.freeze, [">= 3.4.0"])
    s.add_dependency(%q<pry>.freeze, [">= 0.10.3"])
  end
end
