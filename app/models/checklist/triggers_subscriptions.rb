# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Checklist::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_ticket_checklist_subscriptions
  end

  private

  def trigger_ticket_checklist_subscriptions
    Gql::Subscriptions::Ticket::ChecklistUpdates.trigger(
      # Trigger with an empty object in case the checklist was deleted.
      destroyed? ? nil : self,
      arguments: {
        ticket_id: Gql::ZammadSchema.id_from_object(ticket),
      }
    )
  end
end
