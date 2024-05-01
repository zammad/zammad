# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::PasswordCheck < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Check your password'

    argument :password, String, required: true, description: 'Password to check'

    field :success, Boolean, description: 'This indicates if given password matches current user password'

    def ready?(password:)
      throttle!(limit: 3, period: 1.minute, by_identifier: context.current_user.login)
    end

    def resolve(password:)
      success = Service::User::PasswordCheck
        .new(user: context.current_user, password:)
        .execute

      if !success
        return error_response({ field: :password, message: __('The provided password is incorrect.') })
      end

      { success: }
    end
  end
end
