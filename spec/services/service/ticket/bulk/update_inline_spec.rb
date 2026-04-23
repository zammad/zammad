# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::UpdateInline do
  subject(:service_result) { described_class.with_current_user(user).execute(ticket_ids:, perform:) }

  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:tickets)    { create_list(:ticket, 3, group:) }
  let(:perform)    { { input: { title: 'new title' } } }
  let(:ticket_ids) { tickets.map(&:id) }

  describe '#execute' do
    it 'passes given tickets to single item update', aggregate_failures: true do
      allow(Service::Ticket::Bulk::SingleItemUpdate).to receive(:execute).and_call_original

      service_result

      expect(Service::Ticket::Bulk::SingleItemUpdate)
        .to have_received(:execute)
        .with(ticket: tickets[0], perform:, current_user: user)

      expect(Service::Ticket::Bulk::SingleItemUpdate)
        .to have_received(:execute)
        .with(ticket: tickets[1], perform:, current_user: user)

      expect(Service::Ticket::Bulk::SingleItemUpdate)
        .to have_received(:execute)
        .with(ticket: tickets[2], perform:, current_user: user)
    end

    it 'returns async false and the counts' do
      expect(service_result).to include(
        async:                false,
        total:                tickets.size,
        failed_count:         0,
        inaccessible_tickets: [],
        invalid_tickets:      []
      )
    end

    context 'when passing an inaccessible ticket id' do
      let(:inaccessible_ticket) { tickets[1] }

      before do
        error = Service::Ticket::Bulk::SingleItemUpdate::BulkSingleError.new( # rubocop:disable Zammad/ForbidCallingServiceDirectly
          record:         inaccessible_ticket,
          original_error: Pundit::NotAuthorizedError.new(record: inaccessible_ticket, message: 'not authorized')
        )

        allow(Service::Ticket::Bulk::SingleItemUpdate)
          .to receive(:execute)
          .and_call_original

        allow(Service::Ticket::Bulk::SingleItemUpdate)
          .to receive(:execute)
          .with(ticket: tickets[1], perform:, current_user: user)
          .and_raise(error)
      end

      it 'returns inaccessible ticket ids' do
        expect(service_result).to include(
          async:                false,
          total:                3,
          failed_count:         1,
          inaccessible_tickets: [inaccessible_ticket],
          invalid_tickets:      []
        )
      end
    end

    context 'when passing an invalid ticket id' do
      let(:invalid_ticket) { tickets[0] }

      before do
        error = Service::Ticket::Bulk::SingleItemUpdate::BulkSingleError.new( # rubocop:disable Zammad/ForbidCallingServiceDirectly
          record:         invalid_ticket,
          original_error: ActiveRecord::RecordInvalid.new(invalid_ticket)
        )

        allow(Service::Ticket::Bulk::SingleItemUpdate)
          .to receive(:execute)
          .and_call_original

        allow(Service::Ticket::Bulk::SingleItemUpdate)
          .to receive(:execute)
          .with(ticket: tickets[1], perform:, current_user: user)
          .and_raise(error)
      end

      it 'returns invalid ticket ids' do
        expect(service_result).to include(
          async:                false,
          total:                3,
          failed_count:         1,
          invalid_tickets:      [invalid_ticket],
          inaccessible_tickets: []
        )
      end
    end
  end
end
