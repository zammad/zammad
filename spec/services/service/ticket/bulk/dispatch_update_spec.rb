# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::DispatchUpdate do
  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:perform)    { { input: {} } }
  let(:selector)   { { entity_ids: ticket_ids } }
  let(:instance)   { described_class.new(user:, selector:, perform:) }
  let(:tickets)    { create_list(:ticket, 30, group:) }
  let(:ticket_ids) { tickets.map(&:id) }

  describe '#execute' do
    it 'uses selector service to find the tickets to update' do
      allow(Service::Ticket::Bulk::Selector).to receive(:new).and_call_original

      instance.execute

      expect(Service::Ticket::Bulk::Selector)
        .to have_received(:new)
        .with(user:, selector:)
    end

    context 'when few tickets are selected' do
      let(:ticket_ids) { tickets.first(2).map(&:id) }

      it 'calls sync update service' do
        allow(Service::Ticket::Bulk::UpdateInline).to receive(:new).and_call_original

        instance.execute

        expect(Service::Ticket::Bulk::UpdateInline)
          .to have_received(:new)
          .with(user:, ticket_ids: [tickets.first.id, tickets.second.id], perform:)
      end

      it 'passes response from the sync update service' do
        allow_any_instance_of(Service::Ticket::Bulk::UpdateInline)
          .to receive(:execute).and_return({ result: 'ok' })

        expect(instance.execute).to eq({ result: 'ok' })
      end
    end

    context 'when many tickets are selected' do
      it 'schedules background job' do
        allow(TicketBulkUpdateJob).to receive(:perform_later)

        instance.execute

        expect(TicketBulkUpdateJob)
          .to have_received(:perform_later)
          .with(user:, perform:, ticket_ids:)
      end

      it 'pushes pending status to subscription' do
        allow(Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates).to receive(:trigger)

        instance.execute

        expect(Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates)
          .to have_received(:trigger)
          .with({ status: 'pending', total: ticket_ids.size }, scope: user.id)
      end

      it 'returns async flag' do
        expect(instance.execute).to eq({ async: true, total: ticket_ids.size })
      end
    end
  end
end
