# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist::Item::TriggersSubscriptions, current_user_id: 1 do
  let(:checklist_item)    { create(:checklist_item, ticket: referenced_ticket) }
  let(:referenced_ticket) { nil }

  before do
    # Disable subscription triggering by ticket
    # Otherwise it throws off checking if checklist item triggered correct subscriptions
    allow_any_instance_of(Ticket).to receive(:trigger_subscriptions)
  end

  describe '#trigger_item_reference_change_subscription' do
    context 'when new item is created' do
      before do
        allow(Gql::Subscriptions::TicketUpdates).to receive(:trigger)
      end

      it 'triggers the subscription if a ticket is given' do
        item = create(:checklist_item, ticket: create(:ticket))

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(item.ticket, arguments: { ticket_id: item.ticket.to_global_id.to_s })
      end

      it 'does not trigger the subscription if a ticket is not given' do
        create(:checklist_item, ticket: nil)

        expect(Gql::Subscriptions::TicketUpdates).not_to have_received(:trigger)
      end
    end

    context 'when an item with the ticket exists' do
      let(:referenced_ticket) { create(:ticket) }

      before do
        checklist_item
        allow(Gql::Subscriptions::TicketUpdates).to receive(:trigger)
      end

      it 'triggers the subscription twice when changing the ticket', aggregate_failures: true do
        checklist_item.update! ticket: create(:ticket)

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(referenced_ticket, arguments: { ticket_id: referenced_ticket.to_global_id.to_s })

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(checklist_item.ticket, arguments: { ticket_id: checklist_item.ticket.to_global_id.to_s })
      end

      it 'does not trigger the subscription when editing another attribute' do
        checklist_item.update! text: 'changed!'

        expect(Gql::Subscriptions::TicketUpdates).not_to have_received(:trigger)
      end

      it 'triggers the subscription if the ticket is unset' do
        checklist_item.update! ticket: nil

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(referenced_ticket, arguments: { ticket_id: referenced_ticket.to_global_id.to_s })
      end
    end

    context 'when an item without the ticket exists' do
      before do
        checklist_item
        allow(Gql::Subscriptions::TicketUpdates).to receive(:trigger)
      end

      it 'triggers the subscription if the ticket is set' do
        checklist_item.update! ticket: create(:ticket)

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(checklist_item.ticket, arguments: { ticket_id: checklist_item.ticket.to_global_id.to_s })
      end
    end
  end

  describe '#trigger_item_reference_destroy_subscription' do
    before do
      checklist_item
      allow(Gql::Subscriptions::TicketUpdates).to receive(:trigger)
    end

    context 'when a ticket is referenced' do
      let(:referenced_ticket) { create(:ticket) }

      it 'triggers the subscription' do
        checklist_item.destroy!

        expect(Gql::Subscriptions::TicketUpdates)
          .to have_received(:trigger)
          .with(referenced_ticket, arguments: { ticket_id: referenced_ticket.to_global_id.to_s })
      end
    end

    context 'when a ticket is not referenced' do
      it 'does not trigger a subscription' do
        checklist_item.destroy!

        expect(Gql::Subscriptions::TicketUpdates).not_to have_received(:trigger)
      end
    end
  end
end
