# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class ConfigUpdates < BaseSubscription

    # This subscription must not be broadcastable as it sends different data depding on
    #   authenticated state.

    description 'Updates to configuration settings'

    field :setting, Gql::Types::KeyComplexValueType, description: 'Updated setting'

    allow_public_access!

    def update
      return no_update if object['authentication'] && !context.current_user?

      { setting: { key: object['name'], value: object['value'] } }
    end
  end
end
