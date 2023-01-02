# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Recipient < AutocompleteSearch::User

    description 'Search for recipients'

    def coerce_to_result(user)
      {
        value:   user.email,
        label:   user.fullname,
        heading: user.email,
      }
    end

  end
end
