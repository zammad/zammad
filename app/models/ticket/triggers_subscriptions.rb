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

  def trigger_checklist_subscriptions
    return if checklist_items.none?
    return if %i[title state_id].none? { |attr| saved_change_to_attribute?(attr) }

    checklists = checklist_items.compact.map(&:checklist).uniq

    checklists.each do |checklist|
      Gql::Subscriptions::Ticket::ChecklistUpdates.trigger(
        checklist,
        arguments: {
          ticket_id: Gql::ZammadSchema.id_from_object(checklist.ticket),
        }
      )
    end
  end
end
