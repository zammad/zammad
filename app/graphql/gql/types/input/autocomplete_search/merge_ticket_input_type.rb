# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class MergeTicketInputType < InputType

    description 'The default fields for merge ticket autocomplete searches.'

    argument :source_ticket_id, GraphQL::Types::ID, required: false, description: 'Ticket ID'

    def source_ticket
      Gql::ZammadSchema.authorized_object_from_id source_ticket_id, type: ::Ticket, user: context.current_user
    end
  end
end
