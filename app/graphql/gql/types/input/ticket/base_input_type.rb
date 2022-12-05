# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class BaseInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    only_for_ticket_agents = lambda do |payload, context|
      return context.current_user.permissions?('ticket.agent') ? payload : nil
    end

    argument :owner_id, GraphQL::Types::ID, required: false, description: 'The owner of the ticket.', loads: Gql::Types::UserType, prepare: only_for_ticket_agents
    argument :customer_id, GraphQL::Types::ID, required: false, description: 'The customer of the ticket.', loads: Gql::Types::UserType, prepare: only_for_ticket_agents
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization of the ticket.', loads: Gql::Types::OrganizationType
    argument :priority_id, GraphQL::Types::ID, required: false, description: 'The priority of the ticket.', loads: Gql::Types::Ticket::PriorityType, prepare: only_for_ticket_agents
    argument :state_id, GraphQL::Types::ID, required: false, description: 'The state of the ticket.', loads: Gql::Types::Ticket::StateType
    argument :pending_time, GraphQL::Types::ISO8601DateTime, required: false, description: 'The pending time of the ticket.', prepare: only_for_ticket_agents

    transform :remove_nil_fields

    def remove_nil_fields(payload)
      payload.to_h.compact
    end
  end
end
