# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AvatarUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive avatar updates for', loads: Gql::Types::UserType

    description 'Updates to account avatar records'

    field :avatars, [Gql::Types::AvatarType], null: true, description: 'List of avatars for the user'

    # Instance method: allow subscriptions only for the current user
    def authorized?(user:)
      context.current_user.permissions?('user_preferences.avatar') && user.id == context.current_user.id
    end

    def update(user:)
      { avatars: Avatar.list('User', user.id, raw: true) }
    end
  end
end
