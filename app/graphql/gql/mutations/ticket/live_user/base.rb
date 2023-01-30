# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::LiveUser::Base < BaseMutation # rubocop:disable GraphQL/ObjectDescription

    argument :id, GraphQL::Types::ID, loads: Gql::Types::TicketType, as: :ticket, description: 'The ticket which is currently visited.'
    argument :app, Gql::Types::Enum::TaskbarAppType, description: 'Taskbar app to filter for.'

    protected

    def taskbar_key(ticket_id)
      "Ticket-#{ticket_id}"
    end

    def taskbar_item(key, app)
      Taskbar.find_by(key: key, user_id: context.current_user.id, app: app)
    end
  end
end
