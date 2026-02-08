# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class AI::TextToolUpdates < BaseSubscription
    description 'Updated AI text tools'

    field :text_tool_id, GraphQL::Types::ID, description: 'AI text tool ID that was updated'
    field :group_ids, [GraphQL::Types::ID], description: 'The group IDs from the updated AI text tool'
    field :remove_text_tool_id, GraphQL::Types::ID, description: 'The AI text tool ID that was removed'

    class << self
      # Helper methods for triggering with custom payload.
      def trigger_after_create_or_update(text_tool)
        trigger({
                  text_tool_id: Gql::ZammadSchema.id_from_object(text_tool),
                  group_ids:    text_tool.group_ids.map { |id| Gql::ZammadSchema.id_from_internal_id(Group, id) },
                  event:        :create_or_update
                })
      end

      def trigger_after_destroy(text_tool)
        trigger({ text_tool_id: Gql::ZammadSchema.id_from_object(text_tool), event: :destroy })
      end
    end

    def update
      if object[:event] == :destroy
        return { remove_text_tool_id: object[:text_tool_id] }
      end

      { text_tool_id: object[:text_tool_id], group_ids: object[:group_ids] }
    end
  end
end
