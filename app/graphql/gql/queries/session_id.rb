# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class SessionId < BaseQuery

    description 'The sessionId of the currently authenticated user.'

    type String, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    def resolve(...)
      context[:sid]
    end

  end
end
