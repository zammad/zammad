# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket changes.
module Taskbar::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    return true if !saved_change_to_attribute?('preferences')

    # For now it's only needed in the mobile view context.
    return true if !app.eql?('mobile') && !persisted?

    Gql::Subscriptions::TicketLiveUserUpdates.trigger(self, arguments: {
                                                        user_id: Gql::ZammadSchema.id_from_internal_id('User', user_id),
                                                        key:     key,
                                                        app:     app,
                                                      })
  end
end
