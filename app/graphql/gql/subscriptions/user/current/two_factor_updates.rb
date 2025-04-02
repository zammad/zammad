# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TwoFactorUpdates < BaseSubscription

    description 'Updates to current user two factor records'

    subscription_scope :current_user_id

    field :configuration, Gql::Types::User::ConfigurationTwoFactorType, description: 'Configuration information for the current user.'

    def authorized?
      context.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def subscribe
      response
    end

    def update
      response
    end

    private

    def response
      user = context.current_user
      enabled_authentication_methods = user.two_factor_enabled_authentication_methods

      {
        configuration: {
          enabled_authentication_methods: enabled_authentication_methods.each { |item| item[:authentication_method] = item.delete(:method) },
          recovery_codes_exist:           user.auth_two_factor.user_recovery_codes_exists?
        }
      }
    end
  end
end
