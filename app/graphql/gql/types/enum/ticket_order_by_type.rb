# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketOrderByType < BaseEnum
    description 'Option to choose ticket field for SQL sorting'

    value 'TITLE',      'Sort by title'
    value 'NUMBER',     'Sort by ticket number'
    value 'CREATED_AT', 'Sort by create time'
    value 'UPDATED_AT', 'Sort by update time'
  end
end
