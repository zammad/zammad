# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "valid_email2/version"

Gem::Specification.new do |spec|
  spec.name          = "valid_email2"
  spec.version       = ValidEmail2::VERSION
  spec.authors       = ["Micke Lisinge"]
  spec.email         = ["lisinge@gmail.com"]
  spec.description   = %q{ActiveModel validation for email. Including MX lookup and disposable email blacklist}
  spec.summary       = %q{ActiveModel validation for email. Including MX lookup and disposable email blacklist}
  spec.homepage      = "https://github.com/lisinge/valid_email2"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 11.3.0"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_runtime_dependency "mail", "~> 2.5"
  spec.add_runtime_dependency "activemodel", ">= 3.2"
end
