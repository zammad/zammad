# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::DevicesUpdates < BaseSubscription

    description 'Updates to account devices records'

    subscription_scope :current_user_id

    field :devices, [Gql::Types::UserDeviceType], null: true, description: 'List of devices for the user'

    def authorized?
      context.current_user.permissions?('user_preferences.device')
    end

    def update
      { devices: UserDevice.where(user_id: context.current_user.id).reorder(updated_at: :desc, name: :asc) }
    end
  end
end
