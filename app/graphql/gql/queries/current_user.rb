# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Queries
  class CurrentUser < BaseQuery

    description 'Information about the authenticated user'

    type Gql::Types::UserType, null: false

    def resolve(...)
      context[:current_user]
    end

  end
end
