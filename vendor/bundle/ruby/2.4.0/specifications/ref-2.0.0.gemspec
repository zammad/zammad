# -*- encoding: utf-8 -*-
# stub: ref 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ref".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Durand".freeze, "The Ruby Concurrency Team".freeze]
  s.date = "2015-07-10"
  s.description = "Library that implements weak, soft, and strong references in Ruby that work across multiple runtimes (MRI,Jruby and Rubinius). Also includes implementation of maps/hashes that use references and a reference queue.".freeze
  s.email = ["bbdurand@gmail.com".freeze, "concurrent-ruby@googlegroups.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "http://github.com/ruby-concurrency/ref".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "Library that implements weak, soft, and strong references in Ruby.".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version
end
