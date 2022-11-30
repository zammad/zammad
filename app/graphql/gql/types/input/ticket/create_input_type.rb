# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CreateInputType < BaseInputType
    description 'Represents the ticket attributes to be used in ticket create.'

    only_for_ticket_agents = lambda do |payload, context|
      return context.current_user.permissions?('ticket.agent') ? payload : nil
    end

    argument :title, Gql::Types::NonEmptyStringType, description: 'The title of the ticket.'
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
