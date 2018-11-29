# -*- encoding: utf-8 -*-
# stub: kgio 2.11.0 ruby lib
# stub: ext/kgio/extconf.rb

Gem::Specification.new do |s|
  s.name = "kgio".freeze
  s.version = "2.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["kgio hackers".freeze]
  s.date = "2016-12-16"
  s.description = "kgio provides non-blocking I/O methods for Ruby without raising\nexceptions on EAGAIN and EINPROGRESS.  It is intended for use with the\nunicorn Rack server, but may be used by other applications (that run on\nUnix-like platforms).".freeze
  s.email = "kgio-public@bogomips.org".freeze
  s.extensions = ["ext/kgio/extconf.rb".freeze]
  s.extra_rdoc_files = ["LICENSE".freeze, "README".freeze, "TODO".freeze, "NEWS".freeze, "LATEST".freeze, "ISSUES".freeze, "HACKING".freeze, "lib/kgio.rb".freeze, "ext/kgio/accept.c".freeze, "ext/kgio/autopush.c".freeze, "ext/kgio/connect.c".freeze, "ext/kgio/kgio_ext.c".freeze, "ext/kgio/poll.c".freeze, "ext/kgio/wait.c".freeze, "ext/kgio/tryopen.c".freeze]
  s.files = ["HACKING".freeze, "ISSUES".freeze, "LATEST".freeze, "LICENSE".freeze, "NEWS".freeze, "README".freeze, "TODO".freeze, "ext/kgio/accept.c".freeze, "ext/kgio/autopush.c".freeze, "ext/kgio/connect.c".freeze, "ext/kgio/extconf.rb".freeze, "ext/kgio/kgio_ext.c".freeze, "ext/kgio/poll.c".freeze, "ext/kgio/tryopen.c".freeze, "ext/kgio/wait.c".freeze, "lib/kgio.rb".freeze]
  s.homepage = "http://bogomips.org/kgio/".freeze
  s.licenses = ["LGPL-2.1+".freeze]
  s.rubygems_version = "2.6.11".freeze
  s.summary = "kinder, gentler I/O for Ruby".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<olddoc>.freeze, ["~> 1.0"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<olddoc>.freeze, ["~> 1.0"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<olddoc>.freeze, ["~> 1.0"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
  end
end
