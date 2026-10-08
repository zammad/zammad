# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketUserTicketCounterJob, type: :job do

  let!(:customer) { create(:user) }

  let!(:ticket_states) do
    {
      open:   Ticket::State.by_category(:open).first,
      closed: Ticket::State.by_category(:closed).first,
    }
  end

  let!(:tickets) do
    {
      open:   create_list(:ticket, 2, state_id: ticket_states[:open].id, customer_id: customer.id),
      closed: create_list(:ticket, 1, state_id: ticket_states[:closed].id, customer_id: customer.id),
    }
  end

  it 'checks if customer ticket count has been updated in preferences' do
    expect { described_class.perform_now(customer.id, nil, customer.id) }
      .to change { customer.reload.preferences[:tickets_open] }.from(nil).to(tickets[:open].count)
      .and change { customer.reload.preferences[:tickets_closed] }.from(nil).to(tickets[:closed].count)
  end
end
