# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Ci
      module Bundle
        class Orphaned < Tasks::Zammad::Command

          def self.usage
            "#{super} age_in_years"
          end

          ARGUMENT_COUNT = 1

          def self.task_handler
            age = validate_age
            orphaned_gems = find_orphaned_gems(age)

            if orphaned_gems.count.zero?
              puts "No bundled gems released more than #{age} year(s) ago found."
              return
            end

            puts "The following bundled gems were released more than #{age} year(s) ago:"
            orphaned_gems.each do |s|
              puts "  #{s.name}:#{s.version} #{s.date.strftime('%F')}"
            end
            abort
          end

          def self.validate_age
            age = ArgvHelper.argv[1]
            if age.to_i.to_s != age
              abort "Please provide a valid number for 'age_in_years'.\n#{usage}"
            end
            age.to_i
          end

          def self.find_orphaned_gems(age)
            Bundler.definition.specs.select { |s| s.date < age.years.ago }
          end
        end
      end
    end
  end
end
