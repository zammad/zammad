# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class ConfigUpdates < BaseSubscription

    # This subscription must not be broadcastable as it sends different data depding on
    #   authenticated state.

    description 'Updates to configuration settings'

    field :setting, Gql::Types::KeyComplexValueType, description: 'Updated setting'

    def self.authorize(...)
      true # This subscription should be available for all (including unauthenticated) users.
    end

    def update
      return no_update if !object.frontend
      return no_update if object.preferences[:authentication] && !context.current_user?

      # Some setting values use interpolation to reference other settings.
      # This is applied in `Setting.get`, thus direct reading of the value should be avoided.
      value = Setting.get(object.name)

      { setting: { key: object.name, value: value } }
    end
  end
end
