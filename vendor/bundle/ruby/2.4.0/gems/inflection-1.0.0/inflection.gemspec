# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{inflection}
  s.version = "1.0.0"

  s.authors = ["Dan Kubb", "Simon Hafner"]
  s.email = ["hafnersimon", "gmail.com"].join(64.chr)
  s.description = %q{Support library for inflections}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/Tass/extlib/tree/inflection}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Provies english inflection.}
end

