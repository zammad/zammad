# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module Macro::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_save_commit :trigger_create_update_subscriptions
    after_destroy_commit :trigger_destroy_subscriptions
  end

  def trigger_create_update_subscriptions
    Gql::Subscriptions::MacrosUpdate.trigger_after_create_or_update(self)
  end

  def trigger_destroy_subscriptions
    Gql::Subscriptions::MacrosUpdate.trigger_after_destroy(self)
  end
end
