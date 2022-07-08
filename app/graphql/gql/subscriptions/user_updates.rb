# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class UserUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive updates for', loads: Gql::Types::UserType

    description 'Updates to user records'

    field :user, Gql::Types::UserType, null: true, description: 'Updated user'

    # Generally requires logged-in user
    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    # Allow subscriptions only for users where the current user has read permission for.
    def authorized?(user:)
      Pundit.authorize context.current_user, user, :show?
    end

    def update(user:)
      # Safeguard, this should not happen.
      if user.id != object.id
        return no_update
      end

      { user: object }
    end
  end
end
