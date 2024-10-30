# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Ticket::ExternalReferences::IssueTrackerTypeType < BaseEnum
    description 'Possible values for issue tracker type'

    value 'github', 'GitHub'
    value 'gitlab', 'GitLab'
  end
end
