# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Device::Delete < BaseMutation

    description 'Delete a user (session) device.'

    argument :device_id, GraphQL::Types::ID, required: true, loads: Gql::Types::UserDeviceType, description: 'The identifier for the device to be deleted.'

    field :success, Boolean, description: 'This indicates if deleting the user (session) device was successful.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.device')
    end

    def authorized?(device:)
      context.current_user.id == device.user_id
    end

    def resolve(device:)
      Service::User::Device::Delete.new(user: context.current_user, device:).execute

      { success: true }
    end
  end
end
