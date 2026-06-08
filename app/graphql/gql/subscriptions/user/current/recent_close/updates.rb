# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::RecentClose::Updates < BaseSubscription

    description 'Updates for the recently closed items of the current user'

    subscription_scope :current_user_id

    field :recent_close_updated, Boolean, null: true, description: 'The recently closed list of the user has changed.'

    def update
      { recent_close_updated: true }
    end
  end
end
