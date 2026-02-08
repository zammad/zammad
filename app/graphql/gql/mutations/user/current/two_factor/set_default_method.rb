# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::SetDefaultMethod < BaseMutation
    description 'Sets given two factor authentication method as default'

    argument :method_name, String, description: 'Name of the method to set as default'

    field :success, Boolean, description: 'This indicates if setting authentication method as default was successful'

    requires_permission 'user_preferences.two_factor_authentication'

    def resolve(method_name:)
      Service::User::TwoFactor::SetDefaultMethod
        .new(user: context.current_user, method_name:)
        .execute

      { success: true }
    end
  end
end
