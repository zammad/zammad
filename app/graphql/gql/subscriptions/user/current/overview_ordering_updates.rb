# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::OverviewOrderingUpdates < BaseSubscription

    description 'Updates to account overview sorting records'

    subscription_scope :current_user_id

    argument :ignore_user_conditions, Boolean, description: 'Include additional overviews by ignoring user conditions'

    field :overviews, [Gql::Types::OverviewType], null: true, description: 'List of sorted overviews for the user'

    def update(ignore_user_conditions:)
      { overviews: Service::User::Overview::List.new(context.current_user, ignore_user_conditions:).execute }
    end

    def self.trigger_by(user)

      [true, false].each do |ignore_user_conditions|
        trigger(
          nil,
          arguments: { ignore_user_conditions: },
          scope:     user.id
        )
      end
    end
  end
end
