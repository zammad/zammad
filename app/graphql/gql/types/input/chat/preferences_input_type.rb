# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Chat
  class PreferencesInputType < Gql::Types::BaseInputObject
    description 'Chat preferences of an agent, where whatever is left out stays as it is'

    argument :max_windows, Integer, required: false, description: 'How many chats the agent takes at once, from 1 to 20'
    argument :alternative_name, String, required: false, description: 'Name shown to the customer instead of the full name, empty for none'
    argument :avatar_enabled, Boolean, required: false, description: 'Whether the customer sees the avatar of the agent'
    argument :topics, [Gql::Types::Input::Chat::PreferencesTopicInputType, { null: false }], required: false, description: 'The choices for these topics, the others stay as they are'
  end
end
