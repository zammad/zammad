# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasEscalationCalculationImpact', :performs_jobs do

  before do
    queue_adapter.perform_enqueued_jobs = true
    queue_adapter.perform_enqueued_at_jobs = true

    travel_to(DateTime.parse('2013-03-21 09:30:00 UTC'))
  end

  context 'when affected Ticket existed' do

    subject(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 180, solution_time: 240) }

    let(:calendar) { create(:calendar, :business_hours_9_17) }
    let!(:ticket) { create(:ticket) }

    it 'calculates escalation_at' do
      expect { sla }.to change { ticket.reload.escalation_at }.to eq(ticket.created_at + 1.hour)
    end

    it 'calculates first_response_escalation_at' do
      expect { sla }.to change { ticket.reload.first_response_escalation_at }.to eq(ticket.created_at + 1.hour)
    end

    it 'calculates update_escalation_at' do
      expect { sla }.not_to change { ticket.reload.update_escalation_at }.from nil
    end

    it 'calculates close_escalation_at' do
      expect { sla }.to change { ticket.reload.close_escalation_at }.to eq(ticket.created_at + 4.hours)
    end

    context 'when SLA gets updated' do

      before do
        sla
      end

      def first_response_time_change
        sla.update!(first_response_time: 120)
      end

      it 'calculates escalation_at' do
        expect { first_response_time_change }.to change { ticket.reload.escalation_at }.to eq(ticket.created_at + 2.hours)
      end

      it 'calculates first_response_escalation_at' do
        expect { first_response_time_change }.to change { ticket.reload.first_response_escalation_at }.to eq(ticket.created_at + 2.hours)
      end

      it 'calculates update_escalation_at' do
        expect { first_response_time_change }.not_to change { ticket.reload.update_escalation_at }.from nil
      end

      it 'calculates close_escalation_at' do
        expect { first_response_time_change }.not_to change { ticket.reload.close_escalation_at }.from eq(ticket.created_at + 4.hours)
      end
    end
  end

  context 'when matching conditions' do

    context "when matching indirect via 'is not'" do

      subject(:ticket) { create(:ticket, created_at: '2013-03-21 09:30:00 UTC', updated_at: '2013-03-21 09:30:00 UTC') }

      let(:calendar) { create(:calendar) }

      let(:sla_not_matching) do
        create(:sla,
               calendar:            calendar,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is not',
                   value:    %w[1 2 3],
                 },
               },
               first_response_time: 10,
               update_time:         20,
               solution_time:       300)
      end

      let(:sla_matching_indirect) do
        create(:sla,
               calendar:            calendar,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is not',
                   value:    '1',
                 },
               },
               first_response_time: 120,
               update_time:         180,
               solution_time:       240)
      end

      before do
        sla_not_matching
        sla_matching_indirect
        ticket
        ticket.reload
      end

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 13:30:00 UTC')
      end
    end

    context 'when matching ticket.priority_id and article.subject' do
      subject(:ticket) { create(:ticket, created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC') }

      let(:calendar) { create(:calendar) }

      let(:sla) do
        create(:sla,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is',
                   value:    %w[1 2 3],
                 },
                 'article.subject'    => {
                   operator: 'contains',
                   value:    'SLA TEST',
                 },
               },
               calendar:            calendar,
               first_response_time: 60,
               update_time:         120,
               solution_time:       180)
      end

      before do
        sla
        ticket
        create(:'ticket/article', :inbound_email, subject: 'SLA TEST', ticket: ticket, created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC')
        ticket.reload
      end

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-03-21 13:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2016-03-21 13:30:00 UTC')
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-03-21 14:30:00 UTC')
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2016-03-21 15:30:00 UTC')
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil
      end
    end

    context 'when matching ticket.priority_id and ticket.title' do
      subject(:ticket) { create(:ticket, title: 'SLA TEST', created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC') }

      let(:calendar) { create(:calendar) }

      let(:sla) do
        create(:sla,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is',
                   value:    %w[1 2 3],
                 },
                 'ticket.title'       => {
                   operator: 'contains',
                   value:    'SLA TEST',
                 },
               },
               calendar:            calendar,
               first_response_time: 60,
               update_time:         120,
               solution_time:       180)
      end

      before do
        sla
        ticket
        create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC')
        ticket.reload
      end

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-03-21 13:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2016-03-21 13:30:00 UTC')
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-03-21 14:30:00 UTC')
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2016-03-21 15:30:00 UTC')
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil
      end
    end

    context 'when matching ticket.priority_id BUT NOT ticket.title' do
      subject(:ticket) { create(:ticket, created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC') }

      let(:calendar) { create(:calendar) }

      let(:sla) do
        create(:sla,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is',
                   value:    %w[1 2 3],
                 },
                 'ticket.title'       => {
                   operator: 'contains',
                   value:    'SLA TEST',
                 },
               },
               calendar:            calendar,
               first_response_time: 60,
               update_time:         120,
               solution_time:       180)
      end

      before do
        sla
        ticket
        create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2016-03-21 12:30:00 UTC', updated_at: '2016-03-21 12:30:00 UTC')
        ticket.reload
      end

      it 'DOES NOT calculate escalation_at attributes' do
        expect(ticket.escalation_at).to be_nil
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at).to be_nil
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil
      end
    end
  end
end
