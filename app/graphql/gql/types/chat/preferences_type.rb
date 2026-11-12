# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  # Reads what both interfaces store under `preferences[:chat]`, where the old one writes strings:
  #   the limit as text, the topic ids as keys.
  class Chat::PreferencesType < Gql::Types::BaseObject
    description 'Chat preferences of an agent'

    # The default of the old interface.
    DEFAULT_MAX_WINDOWS = 4

    field :max_windows, Integer, null: false, description: 'How many chats the agent takes at once'
    field :alternative_name, String, description: 'Name shown to the customer instead of the full name'
    field :avatar_enabled, Boolean, null: false, description: 'Whether the customer sees the avatar of the agent'
    field :topics, [Gql::Types::Chat::PreferencesTopicType, { null: false }], null: false, description: 'Every active topic with the choices of the agent'
    # Not a preference, but asked for by the chat window only, so it comes along here and not with every user.
    field :has_ticket_create_access, Boolean, null: false, description: 'Whether the agent may create a ticket in at least one group'

    def max_windows
      object[:max_windows].to_i.positive? ? object[:max_windows].to_i : DEFAULT_MAX_WINDOWS
    end

    def alternative_name
      object[:alternative_name].presence
    end

    def avatar_enabled
      object[:avatar_state] != 'disabled'
    end

    def topics
      ::Chat.where(active: true).reorder(:name).map do |topic|
        {
          topic:   topic,
          active:  ::Chat.agent_chat_preference(object, :active, topic.id) == 'on',
          phrases: ::Chat.agent_phrases(object, topic.id),
        }
      end
    end

    def has_ticket_create_access
      context.current_user.group_ids_access(:create).any?
    end
  end
end
