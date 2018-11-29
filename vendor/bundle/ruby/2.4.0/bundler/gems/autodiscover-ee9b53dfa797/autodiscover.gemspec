# -*- encoding: utf-8 -*-
# stub: autodiscover 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "autodiscover".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David King".freeze, "Dan Wanek".freeze]
  s.date = "2018-08-06"
  s.description = "The Autodiscover Service provides information about a Microsoft Exchange environment such as service URLs, versions and many other attributes.".freeze
  s.email = ["dking@bestinclass.com".freeze, "dan.wanek@gmail.com".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "CHANGELOG".freeze, "Gemfile".freeze, "MIT-LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "autodiscover.gemspec".freeze, "lib/autodiscover.rb".freeze, "lib/autodiscover/client.rb".freeze, "lib/autodiscover/debug.rb".freeze, "lib/autodiscover/errors.rb".freeze, "lib/autodiscover/pox_request.rb".freeze, "lib/autodiscover/pox_response.rb".freeze, "lib/autodiscover/server_version_parser.rb".freeze, "lib/autodiscover/version.rb".freeze, "test/fixtures/pox_response.xml".freeze, "test/test_helper.rb".freeze, "test/units/client_test.rb".freeze, "test/units/pox_request_test.rb".freeze, "test/units/pox_response_test.rb".freeze, "test/units/server_version_parser_test.rb".freeze]
  s.homepage = "http://github.com/WinRb/autodiscover".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "2.6.14.1".freeze
  s.summary = "Ruby client for Microsoft's Autodiscover Service".freeze
  s.test_files = ["test/fixtures/pox_response.xml".freeze, "test/test_helper.rb".freeze, "test/units/client_test.rb".freeze, "test/units/pox_request_test.rb".freeze, "test/units/pox_response_test.rb".freeze, "test/units/server_version_parser_test.rb".freeze]

  s.installed_by_version = "2.6.14.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<nori>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<httpclient>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<logging>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.6.0"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    else
      s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
      s.add_dependency(%q<nori>.freeze, [">= 0"])
      s.add_dependency(%q<httpclient>.freeze, [">= 0"])
      s.add_dependency(%q<logging>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.6.0"])
      s.add_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<nokogiri>.freeze, [">= 0"])
    s.add_dependency(%q<nori>.freeze, [">= 0"])
    s.add_dependency(%q<httpclient>.freeze, [">= 0"])
    s.add_dependency(%q<logging>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.6.0"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end
