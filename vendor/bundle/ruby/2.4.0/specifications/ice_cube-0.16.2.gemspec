# -*- encoding: utf-8 -*-
# stub: ice_cube 0.16.2 ruby lib

Gem::Specification.new do |s|
  s.name = "ice_cube".freeze
  s.version = "0.16.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Crepezzi".freeze]
  s.date = "2017-07-10"
  s.description = "ice_cube is a recurring date library for Ruby.  It allows for quick, programatic expansion of recurring date rules.".freeze
  s.email = "john@crepezzi.com".freeze
  s.homepage = "http://seejohnrun.github.com/ice_cube/".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "ice-cube".freeze
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Ruby Date Recurrence Library".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["> 3"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["> 3"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["> 3"])
  end
end
