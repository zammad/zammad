# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'icalendar/recurrence/version'

Gem::Specification.new do |spec|
  spec.name          = "icalendar-recurrence"
  spec.version       = Icalendar::Recurrence::VERSION
  spec.authors       = ["Jordan Raine"]
  spec.email         = ["jnraine@gmail.com"]
  spec.summary       = %q{Provides recurrence to icalendar gem.}
  spec.homepage      = "https://github.com/icalendar/icalendar-recurrence"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'icalendar', '~> 2.0'
  spec.add_runtime_dependency 'ice_cube', '~> 0.13'

  spec.add_development_dependency 'activesupport', '~> 4.0'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.2'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'timecop', '~> 0.6.3'
  spec.add_development_dependency 'tzinfo', '~> 0.3'
end
