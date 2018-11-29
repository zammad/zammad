# -*- encoding: utf-8 -*-

require File.expand_path('../lib/restclient/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'rest-client'
  s.version = RestClient::VERSION
  s.authors = ['REST Client Team']
  s.description = 'A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete.'
  s.license = 'MIT'
  s.email = 'rest.client@librelist.com'
  s.executables = ['restclient']
  s.extra_rdoc_files = ['README.rdoc', 'history.md']
  s.files = `git ls-files -z`.split("\0")
  s.test_files = `git ls-files -z spec/`.split("\0")
  s.homepage = 'https://github.com/rest-client/rest-client'
  s.summary = 'Simple HTTP and REST client for Ruby, inspired by microframework syntax for specifying actions.'

  s.add_development_dependency('webmock', '~> 1.4')
  s.add_development_dependency('rspec', '~> 2.4')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-doc')
  s.add_development_dependency('rdoc', '>= 2.4.2', '< 5.0')

  s.add_dependency('http-cookie', '>= 1.0.2', '< 2.0')
  s.add_dependency('mime-types', '>= 1.16', '< 3.0')
  s.add_dependency('netrc', '~> 0.7')

  s.required_ruby_version = '>= 1.9.2'
end
