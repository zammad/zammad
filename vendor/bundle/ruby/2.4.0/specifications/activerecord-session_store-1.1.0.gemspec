# -*- encoding: utf-8 -*-
# stub: activerecord-session_store 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-session_store".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2017-05-11"
  s.email = "david@loudthinking.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/rails/activerecord-session_store".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.6.11".freeze
  s.summary = "An Action Dispatch session store backed by an Active Record class.".freeze

  s.installed_by_version = "2.6.11" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, ["< 5.2", ">= 4.0"])
      s.add_runtime_dependency(%q<actionpack>.freeze, ["< 5.2", ">= 4.0"])
      s.add_runtime_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0"])
      s.add_runtime_dependency(%q<rack>.freeze, ["< 3", ">= 1.5.2"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.11.2", "~> 1.11"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.1.0"])
    else
      s.add_dependency(%q<activerecord>.freeze, ["< 5.2", ">= 4.0"])
      s.add_dependency(%q<actionpack>.freeze, ["< 5.2", ">= 4.0"])
      s.add_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0"])
      s.add_dependency(%q<rack>.freeze, ["< 3", ">= 1.5.2"])
      s.add_dependency(%q<multi_json>.freeze, [">= 1.11.2", "~> 1.11"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<appraisal>.freeze, ["~> 2.1.0"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, ["< 5.2", ">= 4.0"])
    s.add_dependency(%q<actionpack>.freeze, ["< 5.2", ">= 4.0"])
    s.add_dependency(%q<railties>.freeze, ["< 5.2", ">= 4.0"])
    s.add_dependency(%q<rack>.freeze, ["< 3", ">= 1.5.2"])
    s.add_dependency(%q<multi_json>.freeze, [">= 1.11.2", "~> 1.11"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<appraisal>.freeze, ["~> 2.1.0"])
  end
end
