# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Checklist::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_ticket_checklist_subscriptions
  end

  private

  def trigger_ticket_checklist_subscriptions
    checklist = if instance_of?(::Checklist)
                  self
                elsif instance_of?(::Checklist::Item)
                  # Skip triggering in case the checklist item is created, since it will be triggered by the parent
                  #   checklist update anyway.
                  return true if transaction_include_any_action?(%i[create])

                  self.checklist
                end

    # Skip triggering for checklist templates.
    return true if checklist.ticket.blank?

    Gql::Subscriptions::Ticket::ChecklistUpdates.trigger(
      # Trigger with an empty object in case the checklist was deleted.
      checklist.destroyed? ? nil : checklist,
      arguments: {
        ticket_id: Gql::ZammadSchema.id_from_object(checklist.ticket),
      }
    )
  end
end
