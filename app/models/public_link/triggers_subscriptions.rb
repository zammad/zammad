# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on public link changes.
module PublicLink::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_create  :trigger_subscriptions
    after_update  :trigger_subscriptions
    after_destroy :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    PublicLink::AVAILABLE_SCREENS.each do |screen|
      Gql::Subscriptions::PublicLinkUpdates.trigger(nil, arguments: { screen: screen })
    end
  end
end
