# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module User::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::UserUpdates.trigger(self, arguments: { user_id: Gql::ZammadSchema.id_from_object(self) })
  end
end
