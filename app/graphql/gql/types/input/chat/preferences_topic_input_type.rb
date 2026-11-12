# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Chat
  class PreferencesTopicInputType < Gql::Types::BaseInputObject
    description 'What an agent chooses for one chat topic'

    argument :topic_id, GraphQL::Types::ID, description: 'The chat topic'
    argument :active, Boolean, description: 'Whether the agent takes the customers of the topic'
    argument :phrases, [String, { null: false }], description: 'Greetings to pick from when answering a customer of the topic'
  end
end
