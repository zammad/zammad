# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

require_relative 'concerns/can_check_51_plus_migrations'

module RuboCop
  module Cop
    module Zammad
      class MigrationEnsureIntegerPrimaryKey < Base
        extend AutoCorrector
        include CanCheck51PlusMigrations

        MSG = 'Rails 5.1+ migrations must add id: :integer to ensure primary key is integer, not bigint.'

        RESTRICT_ON_SEND = %i[create_table].freeze

        def on_send(node)
          return if !migration_51_or_newer?(node)

          options = node.arguments.last

          pair_with_id = nil

          if options&.hash_type?
            options.pairs.each do |pair|
              next if !(pair.key.sym_type? && pair.key.value == :id)

              pair_with_id = pair
              next if pair.value.source == ':integer'
              next if pair.value.source == 'false' # allow id: false for ID-less tables
              next if pair.value.source == ':bigserial' # allow id: :bigserial for explicit bigint primary keys

              add_offense(pair.value) do |corrector|
                corrector.replace(pair.value, ':integer')
              end
            end
          end

          return if pair_with_id

          add_offense(node) do |corrector|
            corrector.insert_after(node.arguments.first.source_range, ', id: :integer')
          end
        end
      end
    end
  end
end
