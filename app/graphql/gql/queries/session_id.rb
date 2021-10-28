# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Queries
  class SessionId < BaseQuery

    description 'Information about the current session'

    type String, null: false

    def resolve(...)
      context[:controller].session.id
    end

  end
end
