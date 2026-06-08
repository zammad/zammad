# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module OnlineNotification::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  def trigger_subscriptions
    self.class.trigger_subscriptions(user)
  end

  class_methods do
    def trigger_subscriptions(user)
      Gql::Subscriptions::OnlineNotificationsCount.trigger(user, scope: user.id)
    end
  end
end
