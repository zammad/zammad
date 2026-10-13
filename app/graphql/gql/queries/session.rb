# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Session < BaseQuery

    description 'The session of the currently authenticated user.'

    type Gql::Types::SessionType, null: false

    def resolve(...)
      {
        session_id: context[:controller].session.id,
        after_auth: Auth::AfterAuth.run(context.current_user, context[:controller].session)
      }
    end

  end
end
