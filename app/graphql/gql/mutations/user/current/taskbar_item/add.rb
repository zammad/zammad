# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

      taskbar_item = get_taskbar_item(hash)

      if (object = taskbar_item.to_object)
        ::OnlineNotification.mark_as_seen!(object, context.current_user)
      end

      { taskbar_item: }
    end

    private

    def get_taskbar_item(hash)
      Taskbar.create!(hash)
    rescue ActiveRecord::RecordInvalid
      Taskbar
        .where(user: context.current_user, app: hash[:app], key: hash[:key])
        .first
    end
  end
end
