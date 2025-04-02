# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketStateColorCodeType < BaseEnum
    description 'Ticket state color code'

    value 'open', 'Ready for action.'
    value 'pending', 'Marked as pending; no immediate action required.'
    value 'escalating', 'Requires urgent attention.'
    value 'closed', 'Closed.'
  end
end
