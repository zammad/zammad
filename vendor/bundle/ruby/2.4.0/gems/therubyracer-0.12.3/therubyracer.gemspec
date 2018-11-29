require File.expand_path('../lib/v8/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Charles Lowell"]
  gem.email         = ["javascript-and-friends@googlegroups.com"]
  gem.summary       = "Embed the V8 JavaScript interpreter into Ruby"
  gem.description   = "Call JavaScript code and manipulate JavaScript objects from Ruby. Call Ruby code and manipulate Ruby objects from JavaScript."
  gem.homepage      = "http://github.com/cowboyd/therubyracer"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "therubyracer"
  gem.extensions    = ["ext/v8/extconf.rb"]
  gem.require_paths = ["lib", "ext"]
  gem.version       = V8::VERSION
  gem.license       = 'MIT'

  gem.add_dependency 'ref'
  gem.add_dependency 'libv8', '~> 3.16.14.15'
end
