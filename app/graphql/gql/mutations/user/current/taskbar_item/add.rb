# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TaskbarItem::Add < BaseMutation

    description 'Create a taskbar item for the currently logged-in user.'

    argument :input, Gql::Types::Input::User::TaskbarItemInputType, required: true, description: 'The taskbar item parameters.'

    field :taskbar_item, Gql::Types::User::TaskbarItemType, description: 'The created taskbar item.'

    def resolve(input:)
      hash = input.to_h.merge(
        user_id:     context.current_user.id,
        active:      false,
        preferences: { dirty: input[:dirty].presence || false }
      )

      begin
        taskbar_item = Taskbar.create!(hash)
      rescue ActiveRecord::RecordInvalid
        # noop
      end

      taskbar_item ||= Taskbar.where(user: context.current_user, app: input[:app], key: input[:key]).first

      { taskbar_item: }
    end
  end
end
