# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.shared_examples 'TicketSetsCloseTime' do
  subject { create(described_class.name.underscore) }

  it 'can only be loaded for tickets' do
    expect(described_class).to eq Ticket
  end

  before do
    travel_to Time.zone.now
  end

  it 'resets pending_time seconds' do
    subject.update(state: Ticket::State.lookup(name: 'closed'))
    expect(subject.close_at).to eq(Time.zone.now)
  end
end
