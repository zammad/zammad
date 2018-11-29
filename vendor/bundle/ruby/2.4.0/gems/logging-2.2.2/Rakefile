begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logging/version'

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name         'logging'
  summary      'A flexible and extendable logging library for Ruby'
  authors      'Tim Pease'
  email        'tim.pease@gmail.com'
  url          'http://rubygems.org/gems/logging'
  version      Logging::VERSION

  rdoc.exclude << '^data'
  rdoc.include << '^examples/.*\.rb'
  #rcov.opts    << '-x' << '~/.rvm/'

  use_gmail

  depend_on 'little-plugger', '~> 1.1'
  depend_on 'multi_json',     '~> 1.10'

  depend_on 'test-unit', '~> 3.1', :development => true
  depend_on 'bones-git', '~> 1.3', :development => true
  #depend_on 'bones-rcov',   :development => true
}

