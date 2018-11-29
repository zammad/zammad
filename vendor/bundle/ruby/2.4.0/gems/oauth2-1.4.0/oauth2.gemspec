# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oauth2/version'

Gem::Specification.new do |spec|
  spec.add_dependency 'faraday', ['>= 0.8', '< 0.13']
  spec.add_dependency 'jwt', '~> 1.0'
  spec.add_dependency 'multi_json', '~> 1.3'
  spec.add_dependency 'multi_xml', '~> 0.5'
  spec.add_dependency 'rack', ['>= 1.2', '< 3']
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors       = ['Michael Bleigh', 'Erik Michaels-Ober']
  spec.description   = 'A Ruby wrapper for the OAuth 2.0 protocol built with a similar style to the original OAuth spec.'
  spec.email         = ['michael@intridea.com', 'sferik@gmail.com']
  spec.files         = %w[.document CONTRIBUTING.md LICENSE.md README.md oauth2.gemspec] + Dir['lib/**/*.rb']
  spec.homepage      = 'http://github.com/intridea/oauth2'
  spec.licenses      = %w[MIT]
  spec.name          = 'oauth2'
  spec.require_paths = %w[lib]
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary       = 'A Ruby wrapper for the OAuth 2.0 protocol.'
  spec.version       = OAuth2::Version
end
