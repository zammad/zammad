# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketArticleSenderNameType < BaseEnum
    description 'Ticket article sender names'

    value 'Agent'
    value 'Customer'
    value 'System'
  end
end
