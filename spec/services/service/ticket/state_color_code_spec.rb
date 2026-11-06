# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::StateColorCode do
  def color_of(**attributes)
    described_class.execute(ticket: create(:ticket, **attributes))
  end

  it 'colors a new or open ticket as open, a pending one as pending and a closed one as closed', :aggregate_failures do
    expect(color_of(state: Ticket::State.find_by(name: 'new'))).to eq('open')
    expect(color_of(state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 1.day.from_now)).to eq('pending')
    expect(color_of(state: Ticket::State.find_by(name: 'pending close'), pending_time: 1.day.from_now)).to eq('pending')
    expect(color_of(state: Ticket::State.find_by(name: 'closed'))).to eq('closed')
  end

  it 'colors a pending reminder past its time as open' do
    expect(color_of(state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 1.day.ago)).to eq('open')
  end

  it 'colors an escalating ticket as escalating, whatever its state' do
    ticket = create(:ticket)
    ticket.update_columns(escalation_at: 1.hour.ago)

    expect(described_class.execute(ticket:)).to eq('escalating')
  end
end
