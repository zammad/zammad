# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class MacrosUpdate < BaseSubscription
    description 'Updated macros'

    field :macro_id, GraphQL::Types::ID, description: 'Macro ID that was updated'
    field :group_ids, [GraphQL::Types::ID], description: 'The group IDs from the updated macro'
    field :remove_macro_id, GraphQL::Types::ID, description: 'The macro ID that was removed'

    def authorized?
      true
    end

    class << self
      # Helper methods for triggering with custom payload.
      def trigger_after_create_or_update(macro)
        trigger({
                  macro_id:  Gql::ZammadSchema.id_from_object(macro),
                  group_ids: macro.group_ids.map { |id| Gql::ZammadSchema.id_from_internal_id(Group, id) },
                  event:     :create_or_update
                })
      end

      def trigger_after_destroy(macro)
        trigger({ macro_id: Gql::ZammadSchema.id_from_object(macro), event: :destroy })
      end
    end

    def update
      if object[:event] == :destroy
        return { remove_macro_id: object[:macro_id] }
      end

      { macro_id: object[:macro_id], group_ids: object[:group_ids] }
    end
  end
end
