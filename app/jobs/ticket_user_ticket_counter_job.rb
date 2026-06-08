# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# This job counts *all* user tickets and stores the count in the user preferences
# It is very similar to what Gql::Types::TicketCountType does but not the same!
# Results of this job are used exclusively in the old UI
class TicketUserTicketCounterJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TicketUserTicketCounterJob/23/45"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}}/#{arguments[2]}"
  end

  # TODO: For the new desktop view, we can add a different approach, maybe we don't need this job at all in the future and
  # can only trigger some subscriptions.
  def perform(customer_id, organization_id, updated_by_id)

    # check if update is needed
    customer = User.lookup(id: customer_id)
    return if !customer

    # count open and closed tickets of customer
    ticket_count = {
      closed: 0,
      open:   0,
    }

    return if customer_id == 1

    ticket_count.each_key do |ticket_state_category|
      ticket_states    = Ticket::State.by_category(ticket_state_category)
      ticket_state_ids = ticket_states.map(&:id)
      tickets          = Ticket.where(
        customer_id: customer_id,
        state_id:    ticket_state_ids,
      )
      ticket_count[ticket_state_category] = tickets.count
    end

    needs_update = false
    ticket_count.each_key do |ticket_state_category|
      preferences_key = :"tickets_#{ticket_state_category}"
      next if customer[:preferences][preferences_key] == ticket_count[ticket_state_category]

      needs_update = true
      customer[:preferences][preferences_key] = ticket_count[ticket_state_category]
    end

    if needs_update
      customer.updated_by_id = updated_by_id
      customer.save
    end

    # Trigger subscriptions so that needed lists in the frontend will be refetched
    # This happens regardless of whether the counter needed updating, because also the order of the list could change.
    Gql::Subscriptions::Ticket::ByCustomerUpdates.trigger(nil, arguments: { customer_id: Gql::ZammadSchema.id_from_internal_id(User, customer_id) })

    return if organization_id.blank?

    Gql::Subscriptions::Ticket::ByOrganizationUpdates.trigger(nil, arguments: { organization_id: Gql::ZammadSchema.id_from_internal_id(Organization, organization_id) })
  end
end
