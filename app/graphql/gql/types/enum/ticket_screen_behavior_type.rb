# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TicketScreenBehaviorType < BaseEnum
    description 'Option to choose the ticket screen behavior'

    value 'closeTab', 'Close tab'
    value 'closeTabOnTicketClose', 'Close tab on ticket close'
    value 'closeNextInOverview', 'Next in overview'
    value 'stayOnTab', 'Stay on tab'
  end
end
