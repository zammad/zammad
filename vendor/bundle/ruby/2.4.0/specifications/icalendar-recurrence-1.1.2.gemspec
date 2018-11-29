# -*- encoding: utf-8 -*-
# stub: icalendar-recurrence 1.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "icalendar-recurrence".freeze
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jordan Raine".freeze]
  s.date = "2017-04-20"
  s.email = ["jnraine@gmail.com".freeze]
  s.homepage = "https://github.com/icalendar/icalendar-recurrence".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Provides recurrence to icalendar gem.".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<icalendar>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<ice_cube>.freeze, ["~> 0.13"])
      s.add_development_dependency(%q<activesupport>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<awesome_print>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14"])
      s.add_development_dependency(%q<timecop>.freeze, ["~> 0.6.3"])
      s.add_development_dependency(%q<tzinfo>.freeze, ["~> 0.3"])
    else
      s.add_dependency(%q<icalendar>.freeze, ["~> 2.0"])
      s.add_dependency(%q<ice_cube>.freeze, ["~> 0.13"])
      s.add_dependency(%q<activesupport>.freeze, ["~> 4.0"])
      s.add_dependency(%q<awesome_print>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
      s.add_dependency(%q<timecop>.freeze, ["~> 0.6.3"])
      s.add_dependency(%q<tzinfo>.freeze, ["~> 0.3"])
    end
  else
    s.add_dependency(%q<icalendar>.freeze, ["~> 2.0"])
    s.add_dependency(%q<ice_cube>.freeze, ["~> 0.13"])
    s.add_dependency(%q<activesupport>.freeze, ["~> 4.0"])
    s.add_dependency(%q<awesome_print>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.6.3"])
    s.add_dependency(%q<tzinfo>.freeze, ["~> 0.3"])
  end
end
