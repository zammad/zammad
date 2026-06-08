# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require_relative 'concerns/can_check_51_plus_migrations'

module RuboCop
  module Cop
    module Zammad
      class MigrationEnsureIntegerForeignKey < Base
        extend AutoCorrector
        include CanCheck51PlusMigrations

        MSG = 'Rails 5.1+ migrations must add type: :integer to references setup.'

        RESTRICT_ON_SEND = %i[
          references
          belongs_to
          add_reference
          add_references
        ].freeze

        def on_send(node)
          return if !migration_51_or_newer?(node)

          options = node.arguments.last

          pair_with_type = nil

          if options&.hash_type?
            options.pairs.each do |pair|
              next if !(pair.key.sym_type? && pair.key.value == :type)

              pair_with_type = pair
              next if pair.value.source == ':integer'
              next if pair.value.source == ':bigint' # allow explicit bigint foreign keys

              add_offense(pair.value) do |corrector|
                corrector.replace(pair.value, ':integer')
              end
            end
          end

          return if pair_with_type

          add_offense(node) do |corrector|
            corrector.insert_after(node.arguments.last.source_range, ', type: :integer')
          end
        end
      end
    end
  end
end
