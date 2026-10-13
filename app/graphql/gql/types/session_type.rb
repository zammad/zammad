# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SessionType < Gql::Types::BaseObject
    description 'Session of the currently logged-in user'

    field :id, String, null: false, description: 'Opaque identifier of the session, derived from the session ID.'
    field :after_auth, Gql::Types::Session::AfterAuthType

    def id
      session_id = object[:session_id].to_s
      return if session_id.empty?

      OpenSSL::HMAC.hexdigest('SHA256', Setting.get('application_secret'), session_id)
    end
  end
end
