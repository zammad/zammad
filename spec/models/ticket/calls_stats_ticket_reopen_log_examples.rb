# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'TicketCallsStatsTicketReopenLog' do

  it 'can only be loaded for Ticket' do
    expect(described_class).to eq Ticket
  end

  it 'calls Stats::TicketReopen.log' do
    allow(Stats::TicketReopen).to receive(:log)
    create(described_class.name.underscore)
    expect(Stats::TicketReopen).to have_received(:log)
  end
end
