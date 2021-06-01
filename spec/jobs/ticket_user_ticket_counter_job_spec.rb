# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      open:   [
        create(:ticket, state_id: ticket_states[:open].id, customer_id: customer.id),
        create(:ticket, state_id: ticket_states[:open].id, customer_id: customer.id),
      ],
      closed: [
        create(:ticket, state_id: ticket_states[:closed].id, customer_id: customer.id),
      ],
    }
  end

  it 'checks if customer has no ticket count in preferences' do
    customer.reload
    expect(customer[:preferences][:tickets_open]).to be_falsey
    expect(customer[:preferences][:tickets_closed]).to be_falsey
  end

  it 'checks if customer ticket count has been updated in preferences' do
    described_class.perform_now(
      customer.id,
      customer.id,
    )
    customer.reload

    expect(customer[:preferences][:tickets_open]).to be tickets[:open].count
    expect(customer[:preferences][:tickets_closed]).to be tickets[:closed].count
  end
end
