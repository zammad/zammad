# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Current ticket, needed when composing an article.', loads: Gql::Types::TicketType
      argument :group_id, GraphQL::Types::ID, required: false, description: 'Selected group, needed when creating a new ticket.', loads: Gql::Types::GroupType
    end

    def rendered_body(ticket: nil, group: nil)
      # Fake a ticket object for create screen if a group is present (#4448).
      ticket = Struct.new(:group).new(group) if ticket.nil? && group.present?

      NotificationFactory::Renderer.new(
        objects:  { user: context.current_user, ticket: ticket },
        template: @object.body,
        escape:   false
      ).render(debug_errors: false)
    end
  end
end
