# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Overview::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::TicketOverviewUpdates.trigger(nil)
  end
end
