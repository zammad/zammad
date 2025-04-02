# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Session < BaseQuery

    description 'The sessionId of the currently authenticated user.'

    type Gql::Types::SessionType, null: false

    def resolve(...)
      {
        id:         context[:sid],
        after_auth: Auth::AfterAuth.run(context.current_user, context[:controller].session)
      }
    end

  end
end
