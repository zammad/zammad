# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module OnlineNotification::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  def trigger_subscriptions
    Gql::Subscriptions::OnlineNotificationsCount
      .trigger(user,
               arguments: { user_id: Gql::ZammadSchema.id_from_object(user) })
  end
end
