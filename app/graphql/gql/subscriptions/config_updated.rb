# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Subscriptions
  class ConfigUpdated < BaseSubscription

    def self.requires_authentication?
      false
    end

    description 'Updates to configuration settings'

    field :setting, Gql::Types::KeyComplexValueType, null: true, description: 'Updated setting'

    def update
      setting = object

      if !setting.frontend || (setting.preferences[:authentication] && !context[:current_user])
        return no_update
      end

      { setting: { key: setting.name, value: Setting.get(setting.name) } }
    end
  end
end
