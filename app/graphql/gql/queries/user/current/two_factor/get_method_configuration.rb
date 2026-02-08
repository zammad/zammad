# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TwoFactor::GetMethodConfiguration < BaseQuery
    include Gql::Concerns::HandlesPasswordRevalidationToken

    description 'Fetch list of configured two factor authentication methods.'

    argument :method_name, String, description: 'Name of the method to remove'

    type GraphQL::Types::JSON, null: true

    requires_permission 'user_preferences.two_factor_authentication'

    def resolve(method_name:, token:)
      verify_token!(token)

      Service::User::TwoFactor::GetMethodConfiguration
        .new(user: context.current_user, method_name:)
        .execute
    end
  end
end
