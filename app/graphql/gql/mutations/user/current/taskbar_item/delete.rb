# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::Delete < BaseMutation

    description 'Delete a taskbar item of the currently logged-in user'

    argument :id, GraphQL::Types::ID, required: true, loads: Gql::Types::User::TaskbarItemType, as: :taskbar_item, description: 'The taskbar item ID'

    field :success, Boolean, description: 'This indicates if deleting the user (session) device was successful.'

    def resolve(taskbar_item:)
      taskbar_item.destroy!

      { success: true }
    end
  end
end
