# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Device::Delete < BaseMutation

    description 'Delete a user (session) device.'

    argument :device_id, GraphQL::Types::ID, required: true, loads: Gql::Types::UserDeviceType, loads_pundit_method: :destroy?, description: 'The identifier for the device to be deleted.'

    field :success, Boolean, description: 'This indicates if deleting the user (session) device was successful.'

    requires_permission 'user_preferences.device'

    def resolve(device:)
      Service::User::Device::Delete.new(user: context.current_user, device:).execute

      { success: true }
    end
  end
end
