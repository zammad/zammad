# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket changes.
module Ticket::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :trigger_subscriptions
    after_update_commit :trigger_checklist_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::TicketUpdates.trigger(self, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(self) })
  end

  TRIGGER_CHECKLIST_UPDATE_ON = %w[title state_id group_id].freeze

  def trigger_checklist_subscriptions
    return if !saved_changes.keys.intersect? TRIGGER_CHECKLIST_UPDATE_ON

    referenced_in_checklists = checklist_items.pluck(:checklist_id)

    Checklist
      .where(id: referenced_in_checklists)
      .includes(:ticket)
      .each do |elem|
        Gql::Subscriptions::Ticket::ChecklistUpdates.trigger(
          elem,
          arguments: {
            ticket_id: Gql::ZammadSchema.id_from_object(elem.ticket),
          }
        )
      end
  end
end
