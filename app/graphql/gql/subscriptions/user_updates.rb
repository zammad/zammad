# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class UserUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive updates for'

    description 'Updates to user records'

    field :user, Gql::Types::UserType, description: 'Updated user'

    # Instance method: allow subscriptions only for users where the current user has read permission for.
    def authorized?(user_id:)
      ::Gql::ZammadSchema.authorized_object_from_id user_id, type: ::User, user: context.current_user
    end

    def update(user_id:)
      { user: object }
    end
  end
end
