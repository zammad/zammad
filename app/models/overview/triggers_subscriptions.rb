# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Overview::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    [true, false].each do |ignore_user_conditions|
      Gql::Subscriptions::Ticket::OverviewUpdates.trigger(nil, arguments: { ignore_user_conditions: })
      Gql::Subscriptions::User::Current::Ticket::OverviewUpdates.trigger(nil, arguments: { ignore_user_conditions: })
    end
  end
end
