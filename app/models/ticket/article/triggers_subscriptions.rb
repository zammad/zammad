# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket article changes.
module Ticket::Article::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    # Trigger the TicketUpdate subscription, but pass the article to signal that this article changed.
    Gql::Subscriptions::TicketUpdates.trigger(self, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(ticket) })
  end
end
