# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AutocompleteSearch
  class TicketInputType < InputType

    description 'Input fields for ticket autocomplete searches.'

    argument :except_ticket_internal_id, Integer, required: false, description: 'Optional ticket ID to be filtered out from results'
  end
end
