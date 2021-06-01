# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketEscalationRebuildJob, type: :job do

  before do
    travel_to(DateTime.parse('2013-03-21 09:30:00 UTC'))
  end

  context 'when relevant Ticket is present' do

    subject(:ticket) { create(:ticket) }

    before do
      create(:sla, :condition_blank, first_response_time: 60, update_time: 120, solution_time: 180)
      create(:'ticket/article', :inbound_email, ticket: ticket)
      ticket.update_column(:escalation_at, 2.hours.ago)
      travel(1.hour)
    end

    it 'en-force-es new escalation calculation' do
      expect { described_class.perform_now }.to change { ticket.reload.escalation_at }
    end
  end

  context 'when not relevant Ticket is present' do

    subject(:ticket) { create(:ticket) }

    before do
      create(:'ticket/article', :inbound_email, ticket: ticket)
      ticket.update_column(:escalation_at, 2.hours.ago)
      travel(1.hour)
    end

    it 'does not not change escalation_at' do
      expect { described_class.perform_now }.to change { ticket.reload.escalation_at }
    end
  end

end
