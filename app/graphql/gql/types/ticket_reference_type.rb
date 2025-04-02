# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TicketReferenceType < BaseObject
    description 'Refer to a ticket without raising authorization errors in case of missing permissions'

    field :ticket, Gql::Types::TicketType, description: 'The ticket, if there is read permission'

    def ticket
      object.tap do |ticket|
        Pundit.authorize(context.current_user, ticket, :show?)
      end
    rescue Pundit::NotAuthorizedError
      nil
    end
  end
end
