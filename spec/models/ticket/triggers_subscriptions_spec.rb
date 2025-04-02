# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::TriggersSubscriptions do
  let(:ticket) { create(:ticket) }

  describe '#trigger_subscriptions' do
    before do
      allow(Gql::Subscriptions::TicketUpdates).to receive(:trigger)
    end

    it 'triggers ticket updates subscription when ticket is updated' do
      ticket.update title: 'new title'

      expect(Gql::Subscriptions::TicketUpdates)
        .to have_received(:trigger)
        .with(ticket, arguments: { ticket_id: ticket.to_global_id.to_s })
    end
  end

  describe '#trigger_checklist_subscriptions', :aggregate_failures, current_user_id: 1 do
    let(:own_checklist)              { create(:checklist, ticket:) }
    let(:referenced_checklist)       { create(:checklist).tap { |elem| elem.items.create! ticket: } }
    let(:other_referenced_checklist) { create(:checklist).tap { |elem| 5.times { elem.items.create! ticket: } } }

    before do
      own_checklist
      referenced_checklist
      other_referenced_checklist

      allow(Gql::Subscriptions::Ticket::ChecklistUpdates).to receive(:trigger)
    end

    it 'triggers checklist update ticket is tracked in on title change' do
      ticket.update title: 'new title'

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .to have_received(:trigger)
        .with(referenced_checklist, arguments: { ticket_id: referenced_checklist.ticket.to_global_id.to_s })
    end

    it 'triggers checklist update ticket is tracked in on group change' do
      ticket.update group: create(:group)

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .to have_received(:trigger)
        .with(referenced_checklist, arguments: { ticket_id: referenced_checklist.ticket.to_global_id.to_s })
    end

    it 'triggers checklist update ticket is tracked in on state change' do
      ticket.update state: Ticket::State.find_by(name: 'closed')

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .to have_received(:trigger)
        .with(referenced_checklist, arguments: { ticket_id: referenced_checklist.ticket.to_global_id.to_s })
    end

    it 'triggers checklist update ticket is tracked in twice on state and group change' do
      ticket.update state: Ticket::State.find_by(name: 'closed'), group: create(:group)

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .to have_received(:trigger)
        .with(referenced_checklist, arguments: { ticket_id: referenced_checklist.ticket.to_global_id.to_s })
        .twice
    end

    it 'triggers checklist update once per checklist' do
      ticket.update title: 'new title'

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .to have_received(:trigger)
        .twice
    end

    it 'does not trigger update checklist ticket is tracked in on other change' do
      ticket.update owner: create(:agent)

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .not_to have_received(:trigger)
        .with(referenced_checklist, any_args)
    end

    it 'does not trigger update for checklist of the ticket that was changed' do
      ticket.update owner: create(:agent)

      expect(Gql::Subscriptions::Ticket::ChecklistUpdates)
        .not_to have_received(:trigger)
        .with(own_checklist, any_args)
    end
  end
end
