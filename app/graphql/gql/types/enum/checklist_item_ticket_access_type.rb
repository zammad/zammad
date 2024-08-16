# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class ChecklistItemTicketAccessType < BaseEnum
    description 'All checklist item ticket access type values'

    value 'Granted', 'Access to this ticket is granted'
    value 'Forbidden', 'Access to this ticket is forbidden'
  end
end
