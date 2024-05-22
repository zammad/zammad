# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TwoFactor::Configuration < BaseQuery

    description 'Fetch list of configured two factor authentication methods and .'

    type Gql::Types::User::ConfigurationTwoFactorType, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(...)
      enabled_authentication_methods = context.current_user.two_factor_enabled_authentication_methods

      {
        enabled_authentication_methods: enabled_authentication_methods.each { |item| item[:authentication_method] = item.delete(:method) },
        recovery_codes_exist:           context.current_user.auth_two_factor.user_recovery_codes_exists?
      }
    end
  end
end
