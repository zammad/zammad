# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Chat::MessageType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields

    description 'Message of a chat session, from the customer or the agent'

    field :content, String, null: false, description: 'Sanitized HTML'
    # Dependent like a belongs_to, so a chat agent without ticket permissions sees the name.
    field :created_by, Gql::Types::UserType, null: true, is_dependent_field: true, description: 'The agent who wrote the message, none for the customer'

    # The macro's resolver would ask the batch loader for a missing key too, which costs a
    #   query for every customer message.
    def created_by
      return if object.created_by_id.blank?

      Gql::RecordLoader.for(::User).load(object.created_by_id)
    end
  end
end
