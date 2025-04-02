# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::ChangePassword < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Change user password.'

    argument :current_password, String, required: true, description: 'The current password of the user.'
    argument :new_password, String, required: true, description: 'The new password of the user.'

    field :success, Boolean, description: 'This indicates if changing the password was successful.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.password')
    end

    def ready?(...)
      throttle!(limit: 10, period: 1.minute, by_identifier: context.current_user.login)
    end

    def resolve(current_password:, new_password:)
      begin
        Service::User::ChangePassword.new(
          user:             context.current_user,
          current_password: current_password,
          new_password:     new_password
        ).execute
      rescue PasswordHash::Error
        return error_response({ message: __('The current password you provided is incorrect.'), field: 'current_password' })
      rescue PasswordPolicy::Error => e
        return error_response({ message: e.message, field: 'new_password' })
      end

      { success: true }
    end
  end
end
