# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TwoFactorUpdates < BaseSubscription

    description 'Updates to current user two factor records'

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive avatar updates for', loads: Gql::Types::UserType

    field :configuration, Gql::Types::User::ConfigurationTwoFactorType, description: 'Configuration information for the current user.'

    # Instance method: allow subscriptions only for the current user
    def authorized?(user:)
      context.current_user.permissions?('user_preferences.two_factor_authentication') && user.id == context.current_user.id
    end

    def subscribe(user:)
      response(user)
    end

    def update(user:)
      response(user)
    end

    private

    def response(user)
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
