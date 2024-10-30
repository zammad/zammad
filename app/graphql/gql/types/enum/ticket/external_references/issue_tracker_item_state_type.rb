# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Ticket::ExternalReferences::IssueTrackerItemStateType < BaseEnum
    description 'Possible values for issue tracker item states'

    value 'open'
    value 'closed'
  end
end
