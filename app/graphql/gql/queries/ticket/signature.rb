# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Signature < BaseQuery

    description 'Fetch a ticket signature by group ID'

    argument :group_id, GraphQL::Types::ID, description: 'The group of the ticket.', loads: Gql::Types::GroupType
    argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Current ticket.', loads: Gql::Types::TicketType

    type Gql::Types::SignatureType, null: true

    def resolve(group:, ticket: nil)
      begin
        signature = group_signature(group)
      rescue ActiveRecord::RecordNotFound
        return nil
      end

      return nil if !signature.active?
      return nil if !signature.body?

      signature
    end

    private

    def group_signature(group)
      Signature.find(group.signature_id)
    end
  end
end
