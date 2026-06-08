# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      #
      #
      # @example
      #   # bad
      #   ActiveRecord::Base.descendants
      #   ActiveRecord::Base
      #     .descendants
      #
      #   # good
      #   Models.all.keys

      class PreferModelsAll < Base
        extend AutoCorrector

        def_node_matcher :active_record_descendants?, <<-PATTERN
          $(send (const (const {nil? cbase} :ActiveRecord) :Base) :descendants)
        PATTERN

        MSG = 'Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.'.freeze

        def on_send(node)
          return if active_record_descendants?(node).nil?

          add_offense(node) do |corrector|
            corrector.replace(node, 'Models.all.keys')
          end
        end
      end
    end
  end
end
