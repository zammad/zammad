# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class ConfigUpdated < BaseSubscription

    description 'Updates to configuration settings'

    field :setting, Gql::Types::KeyComplexValueType, null: true, description: 'Updated setting'

    def update
      setting = object

      if !setting.frontend || (setting.preferences[:authentication] && !context.current_user?)
        return no_update
      end

      { setting: { key: setting.name, value: Setting.get(setting.name) } }
    end
  end
end
