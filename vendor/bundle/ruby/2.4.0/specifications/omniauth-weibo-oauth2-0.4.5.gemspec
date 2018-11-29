# -*- encoding: utf-8 -*-
# stub: omniauth-weibo-oauth2 0.4.5 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-weibo-oauth2".freeze
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bin He".freeze]
  s.date = "2017-10-04"
  s.description = "OmniAuth Oauth2 strategy for weibo.com.".freeze
  s.email = "beenhero@gmail.com".freeze
  s.homepage = "https://github.com/beenhero/omniauth-weibo-oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.11".freeze
  s.summary = "OmniAuth Oauth2 strategy for weibo.com.".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 1.5"])
      s.add_runtime_dependency(%q<omniauth-oauth2>.freeze, [">= 1.4.0"])
    else
      s.add_dependency(%q<omniauth>.freeze, ["~> 1.5"])
      s.add_dependency(%q<omniauth-oauth2>.freeze, [">= 1.4.0"])
    end
  else
    s.add_dependency(%q<omniauth>.freeze, ["~> 1.5"])
    s.add_dependency(%q<omniauth-oauth2>.freeze, [">= 1.4.0"])
  end
end
