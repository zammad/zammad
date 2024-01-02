# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SessionType < Gql::Types::BaseObject
    description 'Session of the currently logged-in user'

    field :id, String, null: false
    field :after_auth, Gql::Types::Session::AfterAuthType
  end
end
