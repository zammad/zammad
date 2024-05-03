# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::DevicesUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive devices updates for', loads: Gql::Types::UserType

    description 'Updates to account devices records'

    field :devices, [Gql::Types::UserDeviceType], null: true, description: 'List of devices for the user'

    def authorized?(user:)
      context.current_user.permissions?('user_preferences.device') && user.id == context.current_user.id
    end

    def update(user:)
      { devices: UserDevice.where(user_id: user.id).reorder(updated_at: :desc, name: :asc) }
    end
  end
end
