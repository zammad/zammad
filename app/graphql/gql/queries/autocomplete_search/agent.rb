# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Agent < AutocompleteSearch::User

    description 'Search for agents'

    def find_users(query:, limit:)
      ::User.search(
        query:,
        limit:,
        current_user: context.current_user,
        permissions:  ['ticket.agent'],
      )
    end
  end
end
