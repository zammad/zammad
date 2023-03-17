# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SignatureType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Signature'

    field :name, String, null: false
    field :active, Boolean, null: false
    field :body, String

    field :rendered_body, String do
      argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Current ticket.', loads: Gql::Types::TicketType
    end

    def rendered_body(ticket: nil)
      NotificationFactory::Renderer.new(
        objects:  { user: context.current_user, ticket: ticket },
        template: @object.body,
        escape:   false
      ).render
    end
  end
end
