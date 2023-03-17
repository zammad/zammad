# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class SessionId < BaseQuery

    description 'The sessionId of the currently authenticated user.'

    type String, null: false

    def resolve(...)
      context[:sid]
    end

  end
end
