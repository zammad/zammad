# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Checklist::Item::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_save_commit :trigger_item_reference_change_subscription
    after_destroy_commit :trigger_item_reference_destroy_subscription
  end

  private

  def trigger_item_reference_change_subscription
    return if !saved_change_to_ticket_id?

    if (old_ticket = Ticket.find_by(id: ticket_id_previously_was))
      trigger_subscription(old_ticket)
    end

    trigger_subscription(ticket) if ticket
  end

  def trigger_item_reference_destroy_subscription
    return if !ticket

    trigger_subscription(ticket)
  end

  def trigger_subscription(ticket)
    Gql::Subscriptions::TicketUpdates
      .trigger(ticket, arguments: { ticket_id: Gql::ZammadSchema.id_from_object(ticket) })
  end
end
