# -*- encoding: utf-8 -*-
# stub: oauth 0.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth".freeze
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pelle Braendgaard".freeze, "Blaine Cook".freeze, "Larry Halff".freeze, "Jesse Clark".freeze, "Jon Crosby".freeze, "Seth Fitzsimmons".freeze, "Matt Sanford".freeze, "Aaron Quint".freeze]
  s.date = "2017-05-24"
  s.email = "oauth-ruby@googlegroupspec.com".freeze
  s.executables = ["oauth".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README.rdoc".freeze, "TODO".freeze]
  s.files = ["LICENSE".freeze, "README.rdoc".freeze, "TODO".freeze, "bin/oauth".freeze]
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "OAuth Core Ruby implementation".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_development_dependency(%q<actionpack>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<iconv>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0.9.12"])
      s.add_development_dependency(%q<typhoeus>.freeze, [">= 0.1.13"])
      s.add_development_dependency(%q<em-http-request>.freeze, ["= 0.2.11"])
      s.add_development_dependency(%q<curb>.freeze, [">= 0"])
      s.add_development_dependency(%q<webmock>.freeze, ["< 2.0"])
      s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<rest-client>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_dependency(%q<actionpack>.freeze, ["~> 4.0"])
      s.add_dependency(%q<iconv>.freeze, [">= 0"])
      s.add_dependency(%q<rack>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0.9.12"])
      s.add_dependency(%q<typhoeus>.freeze, [">= 0.1.13"])
      s.add_dependency(%q<em-http-request>.freeze, ["= 0.2.11"])
      s.add_dependency(%q<curb>.freeze, [">= 0"])
      s.add_dependency(%q<webmock>.freeze, ["< 2.0"])
      s.add_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<rest-client>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_dependency(%q<actionpack>.freeze, ["~> 4.0"])
    s.add_dependency(%q<iconv>.freeze, [">= 0"])
    s.add_dependency(%q<rack>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0.9.12"])
    s.add_dependency(%q<typhoeus>.freeze, [">= 0.1.13"])
    s.add_dependency(%q<em-http-request>.freeze, ["= 0.2.11"])
    s.add_dependency(%q<curb>.freeze, [">= 0"])
    s.add_dependency(%q<webmock>.freeze, ["< 2.0"])
    s.add_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rest-client>.freeze, [">= 0"])
  end
end
