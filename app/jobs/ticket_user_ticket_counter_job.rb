# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketUserTicketCounterJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TicketUserTicketCounterJob/23/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def perform(customer_id, updated_by_id)

    # check if update is needed
    customer = User.lookup(id: customer_id)
    return if !customer

    # count open and closed tickets of customer
    ticket_count = {
      closed: 0,
      open:   0,
    }

    if customer_id != 1
      ticket_count.each_key do |ticket_state_category|
        ticket_states    = Ticket::State.by_category(ticket_state_category)
        ticket_state_ids = ticket_states.map(&:id)
        tickets          = Ticket.where(
          customer_id: customer_id,
          state_id:    ticket_state_ids,
        )
        ticket_count[ticket_state_category] = tickets.count
      end
    end

    needs_update = false
    ticket_count.each_key do |ticket_state_category|
      preferences_key = :"tickets_#{ticket_state_category}"
      next if customer[:preferences][preferences_key] == ticket_count[ticket_state_category]

      needs_update = true
      customer[:preferences][preferences_key] = ticket_count[ticket_state_category]
    end
    return if !needs_update

    customer.updated_by_id = updated_by_id
    customer.save
  end
end
