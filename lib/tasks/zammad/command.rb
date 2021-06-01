# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Tasks
  module Zammad

    # Base class for CLI commands in Zammad.
    # Rake is not intended for a real CLI style usage, that is why we need
    #   to apply some workarounds here.
    class Command

      # Infer the rake task name from the class name.
      def self.task_name
        name.downcase.gsub('::', ':').sub('tasks:', '').to_sym
      end

      # Override this if the task needs additional arguments.
      # Currently only a fixed number of arguments is supported.
      ARGUMENT_COUNT = 0

      def self.usage
        "Usage: bundle exec rails #{task_name}"
      end

      def self.register_rake_task
        Rake::Task.define_task task_name => :environment do
          run_task
        end
      end

      def self.run_task
        validate_comandline
        task_handler
      rescue => e
        # A bit more user friendly than plain Rake.
        Rails.logger.error e
        abort "Error: #{e.message}"
      end

      # Prevent the execution of multiple commands at once (mostly because of codebase
      #  self-modification in 'zammad:package:install').
      # Enforce the correct number of expected arguments.
      def self.validate_comandline
        if ARGV.first.eql?(task_name) || ARGV.count != (const_get(:ARGUMENT_COUNT) + 1)
          abort "Error: wrong number of arguments given.\n#{usage}"
        end
        # Rake will try to run additional arguments as tasks, so make sure nothing happens for these.
        ARGV[1..].each { |a| Rake::Task.define_task(a.to_sym => :environment) do; end } # rubocop:disable Style/BlockDelimiters
      end
    end
  end
end
