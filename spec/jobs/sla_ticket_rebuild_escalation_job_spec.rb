require 'rails_helper'

RSpec.describe SlaTicketRebuildEscalationJob, type: :job do

  it 'executes the job' do
    sla = create(:sla)

    expect(Cache).to receive(:delete).with('SLA::List::Active')
    expect(Ticket::Escalation).to receive(:rebuild_all)
    described_class.perform_now(sla.id)
  end
end
