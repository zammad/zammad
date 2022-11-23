# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Recipient < AutocompleteSearch::User

    description 'Search for recipients'

    def coerce_to_result(user)
      {
        value: user.email,
        label: label(user),
      }
    end

    private

    def label(user)
      return user.fullname if user.email.blank?

      "#{user.fullname} <#{user.email}>"
    end
  end
end
