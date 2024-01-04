# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket article changes.
module Ticket::Article::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_create_commit  :trigger_create_subscriptions
    after_update_commit  :trigger_update_subscriptions
    after_destroy_commit :trigger_destroy_subscriptions
  end

  private

  def trigger_create_subscriptions
    Gql::Subscriptions::TicketArticleUpdates.trigger_after_create(self)
  end

  def trigger_update_subscriptions
    Gql::Subscriptions::TicketArticleUpdates.trigger_after_update(self)
  end

  def trigger_destroy_subscriptions
    Gql::Subscriptions::TicketArticleUpdates.trigger_after_destroy(self)
  end
end
