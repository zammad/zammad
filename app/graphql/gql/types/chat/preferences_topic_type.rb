# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Chat::PreferencesTopicType < Gql::Types::BaseObject
    description 'What an agent chose for one chat topic'

    field :topic, Gql::Types::Chat::TopicType, null: false
    field :active, Boolean, null: false, description: 'Whether the agent takes the customers of the topic'
    field :phrases, [String, { null: false }], null: false, description: 'Greetings to pick from when answering a customer of the topic'
  end
end
