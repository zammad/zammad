require 'rails_helper'

RSpec.describe SlaTicketRebuildEscalationJob, type: :job do

  it 'clears the SLA Cache' do
    allow(Cache).to receive(:delete)
    expect(Cache).to receive(:delete).with('SLA::List::Active')
    described_class.perform_now
  end

  it 'triggers Ticket::Escalation rebuild' do
    expect(Ticket::Escalation).to receive(:rebuild_all)
    described_class.perform_now
  end
end
