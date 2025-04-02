# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::SetDefaultMethod < BaseMutation
    description 'Sets given two factor authentication method as default'

    argument :method_name, String, description: 'Name of the method to set as default'

    field :success, Boolean, description: 'This indicates if setting authentication method as default was successful'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(method_name:)
      Service::User::TwoFactor::SetDefaultMethod
        .new(user: context.current_user, method_name:)
        .execute

      { success: true }
    end
  end
end
