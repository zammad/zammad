# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user device changes.
module UserDevice::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::User::Current::DevicesUpdates.trigger(
      nil,
      arguments: {
        user_id: Gql::ZammadSchema.id_from_internal_id('User', user_id)
      }
    )
  end
end
