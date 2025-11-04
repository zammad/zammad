# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketStateTypeCategoryType < BaseEnum
    description 'Ticket state color code'

    ::Ticket::StateType::CATEGORIES.each_key { value it }
  end
end
