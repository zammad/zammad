# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AvatarUpdates < BaseSubscription

    description 'Updates to account avatar records'

    subscription_scope :current_user_id

    field :avatars, [Gql::Types::AvatarType], null: true, description: 'List of avatars for the user'

    requires_permission 'user_preferences.avatar'

    def update
      { avatars: Avatar.list('User', context.current_user.id, raw: true) }
    end
  end
end
