# -*- encoding: utf-8 -*-
# stub: psych 2.2.2 ruby lib
# stub: ext/psych/extconf.rb

Gem::Specification.new do |s|
  s.name = "psych".freeze
  s.version = "2.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aaron Patterson".freeze, "SHIBATA Hiroshi".freeze, "Charles Oliver Nutter".freeze]
  s.date = "2016-11-14"
  s.description = "Psych is a YAML parser and emitter. Psych leverages libyaml[http://pyyaml.org/wiki/LibYAML]\nfor its YAML parsing and emitting capabilities. In addition to wrapping libyaml,\nPsych also knows how to serialize and de-serialize most Ruby objects to and from the YAML format.\n".freeze
  s.email = ["aaron@tenderlovemaking.com".freeze, "hsbt@ruby-lang.org".freeze, "headius@headius.com".freeze]
  s.extensions = ["ext/psych/extconf.rb".freeze]
  s.extra_rdoc_files = ["CHANGELOG.rdoc".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.rdoc".freeze, "README.md".freeze, "ext/psych/extconf.rb".freeze, "psych.rb".freeze, "psych.so".freeze, "psych/class_loader.rb".freeze, "psych/coder.rb".freeze, "psych/core_ext.rb".freeze, "psych/deprecated.rb".freeze, "psych/exception.rb".freeze, "psych/handler.rb".freeze, "psych/handlers/document_stream.rb".freeze, "psych/handlers/recorder.rb".freeze, "psych/json/ruby_events.rb".freeze, "psych/json/stream.rb".freeze, "psych/json/tree_builder.rb".freeze, "psych/json/yaml_events.rb".freeze, "psych/nodes.rb".freeze, "psych/nodes/alias.rb".freeze, "psych/nodes/document.rb".freeze, "psych/nodes/mapping.rb".freeze, "psych/nodes/node.rb".freeze, "psych/nodes/scalar.rb".freeze, "psych/nodes/sequence.rb".freeze, "psych/nodes/stream.rb".freeze, "psych/omap.rb".freeze, "psych/parser.rb".freeze, "psych/scalar_scanner.rb".freeze, "psych/set.rb".freeze, "psych/stream.rb".freeze, "psych/streaming.rb".freeze, "psych/syntax_error.rb".freeze, "psych/tree_builder.rb".freeze, "psych/versions.rb".freeze, "psych/visitors.rb".freeze, "psych/visitors/depth_first.rb".freeze, "psych/visitors/emitter.rb".freeze, "psych/visitors/json_tree.rb".freeze, "psych/visitors/to_ruby.rb".freeze, "psych/visitors/visitor.rb".freeze, "psych/visitors/yaml_tree.rb".freeze, "psych/y.rb".freeze]
  s.homepage = "https://github.com/ruby/psych".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "2.6.13".freeze
  s.summary = "Psych is a YAML parser and emitter".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0.4.1"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    else
      s.add_dependency(%q<rake-compiler>.freeze, [">= 0.4.1"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    end
  else
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0.4.1"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
  end
end
