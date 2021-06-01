# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'TicketResetsPendingTimeSeconds' do
  subject { create(described_class.name.underscore) }

  it 'can only be loaded for tickets' do
    expect(described_class).to eq Ticket
  end

  it 'resets pending_time seconds' do
    subject.update(pending_time: Time.zone.parse('2007-02-10 15:30:45'))
    expect(subject.pending_time).to eq(Time.zone.parse('2007-02-10 15:30:00'))
  end
end
