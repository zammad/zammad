# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::PasswordCheck < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Check your password'

    argument :password, String, required: true, description: 'Password to check'

    field :success, Boolean, description: 'This indicates if given password matches current user password'
    field :token, String, description: 'One-time token which should be included in a subsequent request (where applicable)'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.password')
    end

    def ready?(...)
      throttle!(limit: 10, period: 1.minute, by_identifier: context.current_user.login)
    end

    def resolve(password:)
      password_check = Service::User::PasswordCheck
        .new(user: context.current_user, password:)
        .execute

      if !password_check[:success]
        return error_response({ field: :password, message: __('The provided password is incorrect.') })
      end

      password_check
    end
  end
end
