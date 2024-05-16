# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::OverviewOrderingUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive overview sorting updates for', loads: Gql::Types::UserType

    description 'Updates to account overview sorting records'

    field :overviews, [Gql::Types::OverviewType], null: true, description: 'List of overview sortings for the user'

    def authorized?(user:)
      context.current_user.permissions?('user_preferences.overview_sorting') && user.id == context.current_user.id
    end

    def update(user:)
      { overviews: Service::User::Overview::List.new(user).execute }
    end

    def self.trigger_by(user)
      trigger(
        nil,
        arguments: {
          user_id: Gql::ZammadSchema.id_from_object(user)
        }
      )
    end
  end
end
