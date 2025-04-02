# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::Update < BaseMutation

    description 'Update a taskbar item of the currently logged-in user'

    argument :id, GraphQL::Types::ID, required: true, loads: Gql::Types::User::TaskbarItemType, as: :taskbar_item, description: 'The taskbar item ID'
    argument :input, Gql::Types::Input::User::TaskbarItemInputType, required: true, description: 'The taskbar item parameters.'

    field :taskbar_item, Gql::Types::User::TaskbarItemType, description: 'The updated taskbar item.'

    def resolve(taskbar_item:, input:)
      preferences = taskbar_item.preferences || {}
      preferences[:dirty] = input[:dirty].presence || false

      input.delete(:dirty)

      hash = input.to_h.merge(
        preferences: preferences
      )

      taskbar_item.update!(hash)

      { taskbar_item: }
    end
  end
end
