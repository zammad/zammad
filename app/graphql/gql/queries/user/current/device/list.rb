# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Device::List < BaseQuery

    description 'Fetch available device list of the currently logged-in user'

    type [Gql::Types::UserDeviceType], null: true

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.device')
    end

    def resolve(...)
      UserDevice.where(user_id: context.current_user.id).reorder(updated_at: :desc, name: :asc)
    end
  end
end
