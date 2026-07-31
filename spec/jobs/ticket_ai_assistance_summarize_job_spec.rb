# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketAIAssistanceSummarizeJob, type: :job do
  describe '#perform' do
    let(:ticket)          { create(:ticket) }
    let(:locale)          { 'en' }
    let(:current_user)    { create(:agent) }
    let(:regeneration_of) { nil }

    def perform
      described_class.perform_now(ticket, locale, current_user:, regeneration_of: nil)
    end

    before do
      allow(Sessions).to receive(:broadcast)
      allow(Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates).to receive(:trigger)
    end

    context 'when Summarize service returns' do
      let(:service_result) { Service::AI::Feature::Result[content:, ai_analytics_run:] }
      let(:content)          { nil }
      let(:ai_analytics_run) { nil }

      before do
        allow(Service::Ticket::AIAssistance::Summarize)
          .to receive(:execute)
          .and_return(service_result)
      end

      it 'forwards given arguments to Summarize service' do
        perform

        expect(Service::Ticket::AIAssistance::Summarize)
          .to have_received(:execute)
          .with(ticket:, locale:, current_user:, regeneration_of:)
      end

      context 'when return is nil' do
        it 'triggers subscription with an empty summary for the new view' do
          perform

          expect(Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates)
            .to have_received(:trigger)
            .with(
              { summary: {} },
              arguments: { ticket_id: ticket.to_global_id.to_s, locale: }
            )
        end

        it 'broadcasts update to the old app' do
          perform

          expect(Sessions)
            .to have_received(:broadcast)
            .with({
                    event: 'ticket::summary::update',
                    data:  { ticket_id: ticket.id, locale: }
                  })
        end
      end

      context 'when return is valid data' do
        let(:content) { { customer_request: 'Short summary' } }
        let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }

        it 'triggers subscription with the returned summary for the new view' do
          perform

          expect(Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates)
            .to have_received(:trigger)
            .with(
              { summary: content, ai_analytics_run_id: ai_analytics_run.id },
              arguments: { ticket_id: ticket.to_global_id.to_s, locale: }
            )
        end

        it 'broadcasts update to the old app' do
          perform

          expect(Sessions)
            .to have_received(:broadcast)
            .with({
                    event: 'ticket::summary::update',
                    data:  { ticket_id: ticket.id, locale: }
                  })
        end
      end
    end

    context 'when error is raised' do
      before do
        allow(Service::Ticket::AIAssistance::Summarize)
          .to receive(:execute)
          .and_raise(StandardError, 'Something went wrong')
      end

      it 'triggers subscription with the error for the new view' do
        perform

        expect(Gql::Subscriptions::Ticket::AIAssistance::SummaryUpdates)
          .to have_received(:trigger)
          .with(
            { error: { message: 'Something went wrong', exception: 'StandardError' } },
            arguments: { ticket_id: ticket.to_global_id.to_s, locale: }
          )
      end

      it 'broadcasts update to the old app with the error flag' do
        perform

        expect(Sessions)
          .to have_received(:broadcast)
          .with({
                  event: 'ticket::summary::update',
                  data:  { ticket_id: ticket.id, error: true, ai_analytics_run_id: nil }
                })
      end
    end
  end
end
