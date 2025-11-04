# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Rudimentary implementation of TriggerType to make history work.
module Gql::Types::AI
  class AgentType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'AI::Agents'

    field :name, String, null: false, description: 'Name of the AI Agent'
  end
end
