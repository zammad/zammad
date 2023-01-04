# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      setting = object

      if !setting.frontend || (setting.preferences[:authentication] && !context.current_user?)
        return no_update
      end

      { setting: { key: setting.name, value: setting.state_current[:value] } }
    end
  end
end
