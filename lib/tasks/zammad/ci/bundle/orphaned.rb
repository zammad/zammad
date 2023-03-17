# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Ci
      module Bundle
        class Orphaned < Tasks::Zammad::Command

          def self.usage
            "#{super} age_in_years"
          end

          def self.description
            'Check for bundled gems that seem to be outdated/orphaned'
          end

          ARGUMENT_COUNT = 1

          def self.task_handler
            age = validate_age
            orphaned_gems = find_orphaned_gems(age).sort_by(&:name)
            unreleased_gems = find_unreleased_gems.sort_by(&:name)

            if orphaned_gems.count.zero? && unreleased_gems.count.zero?
              puts "No bundled gems released more than #{age} year(s) ago found."
              return
            end

            print_orphaned_errors(orphaned_gems, age)
            print_unreleased_errors(unreleased_gems)

            abort
          end

          def self.print_orphaned_errors(orphaned_gems, age)
            return if !orphaned_gems.count.positive?

            warn "\nThe following bundled gems were released more than #{age} year(s) ago:"
            orphaned_gems.each do |s|
              warn "  #{s.name}:#{s.version} #{s.date.strftime('%F')}"
              print_dependencies_of(s.name)
            end
          end

          def self.print_unreleased_errors(unreleased_gems)
            return if !unreleased_gems.count.positive?

            warn "\nThe following bundled gems are installed from git sources and not from official releases:"
            unreleased_gems.each do |s|
              warn "  #{s.name}:#{s.version} #{s.source}"
              print_dependencies_of(s.name)
            end
          end

          def self.validate_age
            age = ArgvHelper.argv[1]
            if age.to_i.to_s != age
              abort "Please provide a valid number for 'age_in_years'.\n#{usage}"
            end
            age.to_i
          end

          def self.print_dependencies_of(name, level = 0)
            deps = dependency_map[name]
            return if !deps

            deps.each do |dep|
              warn "  #{'  ' * level} - #{dep}"
              print_dependencies_of(dep, level + 1)
            end
          end

          def self.dependency_map
            return @dependencies if @dependencies

            @dependencies = {}
            Bundler.definition.specs.each do |spec|
              spec.dependencies.each do |dep|
                @dependencies[dep.name] ||= []
                @dependencies[dep.name].push spec.name
              end
            end
            @dependencies
          end

          ALLOWLIST = [
            #
            # development only
            #
            'pry-remote',
            'slop', # dependency of pry-remote
            'interception', # dependency of pry-rescue
            #
            # production
            #
            'rails-dom-testing', # Rails core stuff
            # widely used and/or small language extensions, seem to be safe
            'ffi-compiler',
            'htmlentities',
            'ice_nine',
            'inflection',
            'multi_xml',
            'promise.rb',
            'thread_safe',
            'unf',
          ].freeze

          def self.find_orphaned_gems(age)
            obsolete_allowlist_entries = ALLOWLIST - Bundler.definition.specs.map(&:name)
            raise "#{obsolete_allowlist_entries} were allowlisted but not used in the Gemfile." if obsolete_allowlist_entries.count.positive?

            Bundler.definition.specs.select { |s| (s.date < age.years.ago) && ALLOWLIST.exclude?(s.name) }
          end

          def self.find_unreleased_gems
            Bundler.definition.specs.select { |s| s.source.is_a?(Bundler::Source::Git) }
          end
        end
      end
    end
  end
end
