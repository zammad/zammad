# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::RemoveMethod < BaseMutation
    include Gql::Concerns::HandlesPasswordRevalidationToken

    description 'Removes given two factor authentication method'

    argument :method_name, String, description: 'Name of the method to remove'

    field :success, Boolean, description: 'This indicates if removing authentication method was successful'

    requires_permission 'user_preferences.two_factor_authentication'

    def resolve(method_name:, token:)
      token_object = verify_token!(token)

      Service::User::TwoFactor::RemoveMethod
        .with_current_user(context.current_user)
        .execute(method_name:)

      token_object.destroy

      { success: true }
    end
  end
end
