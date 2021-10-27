# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Queries
  class Session < BaseQuery

    description 'Information about the current user session'

    type Gql::Types::SessionType, null: false

    def resolve(...)

      session = context[:controller].session

      {
        session_id: session.id,
        data:       session.to_hash
      }

    end

  end
end
