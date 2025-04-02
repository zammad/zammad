# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::TouchLastContact < BaseMutation

    description 'Update last_contact_at for a taskbar item of the currently logged-in user'

    argument :id, GraphQL::Types::ID, required: true, loads: Gql::Types::User::TaskbarItemType, as: :taskbar_item, description: 'The taskbar item ID'

    field :taskbar_item, Gql::Types::User::TaskbarItemType, description: 'The updated taskbar item.'

    def resolve(taskbar_item:)
      taskbar_item.touch_last_contact!

      { taskbar_item: }
    end
  end
end
