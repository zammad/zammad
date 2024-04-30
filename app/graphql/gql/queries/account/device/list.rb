# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Account::Device::List < BaseQuery

    description 'Fetch available device list of the currently logged-in user'

    type [Gql::Types::UserDeviceType], null: true

    def authorized?(...)
      context.current_user.permissions?('user_preferences.device')
    end

    def resolve(...)
      UserDevice.where(user_id: context.current_user.id).reorder(updated_at: :desc, name: :asc)
    end
  end
end
