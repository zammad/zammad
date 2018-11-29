# -*- encoding: utf-8 -*-
# stub: telegramAPI 1.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "telegramAPI".freeze
  s.version = "1.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Benedetto Nespoli".freeze]
  s.date = "2018-05-16"
  s.description = "A lightweight wrapper in Ruby for Telegram API Bots".freeze
  s.email = "benedetto.nespoli@gmail.com".freeze
  s.homepage = "https://github.com/bennesp/telegramAPI".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "2.6.14.1".freeze
  s.summary = "Telegram API Wrapper for Bots".freeze

  s.installed_by_version = "2.6.14.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>.freeze, [">= 2.0.2", "~> 2.0"])
    else
      s.add_dependency(%q<rest-client>.freeze, [">= 2.0.2", "~> 2.0"])
    end
  else
    s.add_dependency(%q<rest-client>.freeze, [">= 2.0.2", "~> 2.0"])
  end
end
