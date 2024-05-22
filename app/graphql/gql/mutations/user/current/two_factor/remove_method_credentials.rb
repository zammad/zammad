# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::RemoveMethodCredentials < BaseMutation
    description 'Removes given two factor authentication method'

    argument :method_name, String, description: 'Name of the method to remove'
    argument :credential_id, String, description: 'Name of the method to remove'

    field :success, Boolean, description: 'This indicates if removing authentication method was successful'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(method_name:, credential_id:)
      Service::User::TwoFactor::RemoveMethodCredentials
        .new(user: context.current_user, method_name:, credential_id:)
        .execute

      { success: true }
    end
  end
end
