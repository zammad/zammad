# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nestful/version'

Gem::Specification.new do |gem|
  gem.name          = "nestful"
  gem.version       = Nestful::VERSION
  gem.authors       = ["Alex MacCaw"]
  gem.email         = ["info@eribium.org"]
  gem.summary       = %q{Simple Ruby HTTP/REST client with a sane API}
  gem.homepage      = "https://github.com/maccman/nestful"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
