# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CreateInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'Represents the ticket attributes to be used in ticket create/update.'

    only_for_ticket_agents = lambda do |payload, context|
      return context.current_user.permissions?('ticket.agent') ? payload : nil
    end

    argument :title, Gql::Types::NonEmptyStringType, description: 'The title of the ticket.'
    argument :owner_id, GraphQL::Types::ID, required: false, description: 'The owner of the ticket.', loads: Gql::Types::UserType, prepare: only_for_ticket_agents
    argument :customer_id, GraphQL::Types::ID, required: false, description: 'The customer of the ticket.', loads: Gql::Types::UserType, prepare: only_for_ticket_agents
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization of the ticket.', loads: Gql::Types::OrganizationType
    argument :group_id, GraphQL::Types::ID, description: 'The group of the ticket.', loads: Gql::Types::GroupType
    argument :priority_id, GraphQL::Types::ID, required: false, description: 'The priority of the ticket.', loads: Gql::Types::Ticket::PriorityType, prepare: only_for_ticket_agents
    argument :state_id, GraphQL::Types::ID, required: false, description: 'The state of the ticket.', loads: Gql::Types::Ticket::StateType
    argument :pending_time, GraphQL::Types::ISO8601DateTime, required: false, description: 'The pending time of the ticket.', prepare: only_for_ticket_agents
    argument :article, Gql::Types::Input::Ticket::ArticleInputType, required: false, description: 'The article data.'
    argument :tags, [String], required: false, description: 'The tags that should be assigned to the new ticket.', prepare: only_for_ticket_agents

    transform :lazy_default_values

    def lazy_default_values(payload)
      payload.to_h.tap do |result|

        result[:state] ||= Ticket::State.find_by(default_create: true)

        if context.current_user.permissions?('ticket.customer')
          result[:customer_id] ||= context.current_user.id
        end
      end
    end
  end
end
