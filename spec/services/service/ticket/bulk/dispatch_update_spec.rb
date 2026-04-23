# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::DispatchUpdate do
  subject(:service_result) { described_class.with_current_user(user).execute(selector:, perform:) }

  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:perform)    { { input: {} } }
  let(:selector)   { { entity_ids: ticket_ids } }
  let(:tickets)    { create_list(:ticket, 30, group:) }
  let(:ticket_ids) { tickets.map(&:id) }

  describe '#execute' do
    it 'uses selector service to find the tickets to update' do
      allow(Service::Ticket::Bulk::Selector).to receive(:execute).and_call_original

      service_result

      expect(Service::Ticket::Bulk::Selector)
        .to have_received(:execute)
        .with(selector:, current_user: user)
    end

    context 'when few tickets are selected' do
      let(:ticket_ids) { tickets.first(2).map(&:id) }

      it 'calls sync update service' do
        allow(Service::Ticket::Bulk::UpdateInline).to receive(:execute).and_call_original

        service_result

        expect(Service::Ticket::Bulk::UpdateInline)
          .to have_received(:execute)
          .with(ticket_ids: [tickets.first.id, tickets.second.id], perform:, current_user: user)
      end

      it 'passes response from the sync update service' do
        allow(Service::Ticket::Bulk::UpdateInline)
          .to receive(:execute).and_return({ result: 'ok' })

        expect(service_result).to eq({ result: 'ok' })
      end
    end

    context 'when many tickets are selected' do
      it 'schedules background job' do
        allow(TicketBulkUpdateJob).to receive(:perform_later)

        service_result

        expect(TicketBulkUpdateJob)
          .to have_received(:perform_later)
          .with(user:, perform:, ticket_ids:)
      end

      it 'pushes pending status to subscription' do
        allow(Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates).to receive(:trigger)

        service_result

        expect(Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates)
          .to have_received(:trigger)
          .with({ status: 'pending', total: ticket_ids.size }, scope: user.id)
      end

      it 'returns async flag' do
        expect(service_result).to eq({ async: true, total: ticket_ids.size })
      end
    end
  end
end
