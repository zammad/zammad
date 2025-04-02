# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module User::TwoFactorPreference::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::User::Current::TwoFactorUpdates.trigger(nil, scope: user.id)
  end
end
