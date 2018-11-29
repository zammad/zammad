# -*- encoding: utf-8 -*-
# stub: logging 2.1.0.48 ruby lib

Gem::Specification.new do |s|
  s.name = "logging".freeze
  s.version = "2.1.0.48"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Pease".freeze]
  s.date = "2017-01-08"
  s.description = "**Logging** is a flexible logging library for use in Ruby programs based on the\ndesign of Java's log4j library. It features a hierarchical logging system,\ncustom level names, multiple output destinations per log event, custom\nformatting, and more.".freeze
  s.email = "tim.pease@gmail.com".freeze
  s.extra_rdoc_files = ["History.txt".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "History.txt".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "examples/appenders.rb".freeze, "examples/classes.rb".freeze, "examples/colorization.rb".freeze, "examples/custom_log_levels.rb".freeze, "examples/fork.rb".freeze, "examples/formatting.rb".freeze, "examples/hierarchies.rb".freeze, "examples/layouts.rb".freeze, "examples/lazy.rb".freeze, "examples/loggers.rb".freeze, "examples/mdc.rb".freeze, "examples/names.rb".freeze, "examples/rails4.rb".freeze, "examples/reusing_layouts.rb".freeze, "examples/rspec_integration.rb".freeze, "examples/simple.rb".freeze, "lib/logging.rb".freeze, "lib/logging/appender.rb".freeze, "lib/logging/appenders.rb".freeze, "lib/logging/appenders/buffering.rb".freeze, "lib/logging/appenders/console.rb".freeze, "lib/logging/appenders/file.rb".freeze, "lib/logging/appenders/io.rb".freeze, "lib/logging/appenders/rolling_file.rb".freeze, "lib/logging/appenders/string_io.rb".freeze, "lib/logging/appenders/syslog.rb".freeze, "lib/logging/color_scheme.rb".freeze, "lib/logging/diagnostic_context.rb".freeze, "lib/logging/filter.rb".freeze, "lib/logging/filters.rb".freeze, "lib/logging/filters/level.rb".freeze, "lib/logging/layout.rb".freeze, "lib/logging/layouts.rb".freeze, "lib/logging/layouts/basic.rb".freeze, "lib/logging/layouts/parseable.rb".freeze, "lib/logging/layouts/pattern.rb".freeze, "lib/logging/log_event.rb".freeze, "lib/logging/logger.rb".freeze, "lib/logging/proxy.rb".freeze, "lib/logging/rails_compat.rb".freeze, "lib/logging/repository.rb".freeze, "lib/logging/root_logger.rb".freeze, "lib/logging/utils.rb".freeze, "lib/logging/version.rb".freeze, "lib/rspec/logging_helper.rb".freeze, "lib/spec/logging_helper.rb".freeze, "logging.gemspec".freeze, "script/bootstrap".freeze, "script/console".freeze, "test/appenders/test_async_flushing.rb".freeze, "test/appenders/test_buffered_io.rb".freeze, "test/appenders/test_console.rb".freeze, "test/appenders/test_file.rb".freeze, "test/appenders/test_io.rb".freeze, "test/appenders/test_rolling_file.rb".freeze, "test/appenders/test_string_io.rb".freeze, "test/appenders/test_syslog.rb".freeze, "test/benchmark.rb".freeze, "test/layouts/test_basic.rb".freeze, "test/layouts/test_color_pattern.rb".freeze, "test/layouts/test_json.rb".freeze, "test/layouts/test_pattern.rb".freeze, "test/layouts/test_yaml.rb".freeze, "test/performance.rb".freeze, "test/setup.rb".freeze, "test/test_appender.rb".freeze, "test/test_color_scheme.rb".freeze, "test/test_filter.rb".freeze, "test/test_layout.rb".freeze, "test/test_log_event.rb".freeze, "test/test_logger.rb".freeze, "test/test_logging.rb".freeze, "test/test_mapped_diagnostic_context.rb".freeze, "test/test_nested_diagnostic_context.rb".freeze, "test/test_proxy.rb".freeze, "test/test_repository.rb".freeze, "test/test_root_logger.rb".freeze, "test/test_utils.rb".freeze]
  s.homepage = "http://rubygems.org/gems/logging".freeze
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubyforge_project = "logging".freeze
  s.rubygems_version = "2.5.2".freeze
  s.summary = "A flexible and extendable logging library for Ruby".freeze
  s.test_files = ["test/appenders/test_async_flushing.rb".freeze, "test/appenders/test_buffered_io.rb".freeze, "test/appenders/test_console.rb".freeze, "test/appenders/test_file.rb".freeze, "test/appenders/test_io.rb".freeze, "test/appenders/test_rolling_file.rb".freeze, "test/appenders/test_string_io.rb".freeze, "test/appenders/test_syslog.rb".freeze, "test/layouts/test_basic.rb".freeze, "test/layouts/test_color_pattern.rb".freeze, "test/layouts/test_json.rb".freeze, "test/layouts/test_pattern.rb".freeze, "test/layouts/test_yaml.rb".freeze, "test/test_appender.rb".freeze, "test/test_color_scheme.rb".freeze, "test/test_filter.rb".freeze, "test/test_layout.rb".freeze, "test/test_log_event.rb".freeze, "test/test_logger.rb".freeze, "test/test_logging.rb".freeze, "test/test_mapped_diagnostic_context.rb".freeze, "test/test_nested_diagnostic_context.rb".freeze, "test/test_proxy.rb".freeze, "test/test_repository.rb".freeze, "test/test_root_logger.rb".freeze, "test/test_utils.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
      s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<bones-git>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<bones>.freeze, [">= 3.8.4"])
    else
      s.add_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
      s.add_dependency(%q<multi_json>.freeze, ["~> 1.10"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.1"])
      s.add_dependency(%q<bones-git>.freeze, ["~> 1.3"])
      s.add_dependency(%q<bones>.freeze, [">= 3.8.4"])
    end
  else
    s.add_dependency(%q<little-plugger>.freeze, ["~> 1.1"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.10"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.1"])
    s.add_dependency(%q<bones-git>.freeze, ["~> 1.3"])
    s.add_dependency(%q<bones>.freeze, [">= 3.8.4"])
  end
end
