# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::RecentView::Updates < BaseSubscription

    description 'Updates to the recently viewed items of the current user'

    subscription_scope :current_user_id

    field :recent_views_updated, Boolean, null: true, description: 'The recent view list of the user has changed.'

    def update
      { recent_views_updated: true }
    end
  end
end
