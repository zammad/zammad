# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TicketExternalReferencesType < BaseObject
    description 'Links attached to a ticket and pointing to external services'

    field :github, [Gql::Types::UriHttpStringType], description: 'Returns exising links for the github integration'
    field :gitlab, [Gql::Types::UriHttpStringType], description: 'Returns exising links for the gitlab integration'
    field :idoit,  [Integer], description: 'Returns exising object ids for the idoit integration'
  end
end
