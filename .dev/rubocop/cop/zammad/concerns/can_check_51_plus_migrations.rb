# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      module CanCheck51PlusMigrations
        VERSION_THRESHOLD   = 5.1

        # Apply to 7.0 migrations and newer
        MIGRATION_THRESHOLD = 20250519095403 # rubocop:disable Style/NumericLiterals

        def migration_51_or_newer?(node)
          return false if old_migration?

          migration?(node) && rails_51_or_newer?(node)
        end

        private

        def migration?(node)
          superclass(node)&.children&.at(0)&.const_name == 'ActiveRecord::Migration'
        end

        def old_migration?
          file_timestamp = File.basename(processed_source.file_path)[%r{\A\d+}]

          return false if !file_timestamp

          file_timestamp.to_i < MIGRATION_THRESHOLD
        end

        def rails_51_or_newer?(node)
          klass = superclass(node)

          return false if !klass.send_type?

          klass.arguments.first.value.to_f >= VERSION_THRESHOLD
        end

        def superclass(node)
          node
            .each_ancestor(:class)
            .first
            &.parent_class
        end
      end
    end
  end
end
