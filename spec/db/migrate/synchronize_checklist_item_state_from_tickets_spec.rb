# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SynchronizeChecklistItemStateFromTickets, :aggregate_failures, current_user_id: 1, type: :db_migration do
  let!(:checklist) do
    create(:checklist, ticket: create(:ticket), item_count: 1).tap do |checklist|
      if another_ticket
        checklist.items.last.update!(text: "Ticket##{another_ticket.number}", ticket_id: another_ticket.id)
      end
      checklist.items.last.update!(checked: checklist_item_checked)
      checklist.reload
    end
  end
  let(:checklist_item_checked) { true }
  let(:another_ticket)         { create(:ticket, state: Ticket::State.find_by(name: state_name)) }
  let(:state_name)             { 'open' }

  context 'without linked ticket' do
    let(:another_ticket) { nil }

    context 'when checklist item is checked' do
      it 'does not change the checklist item' do
        expect(checklist.items.first.checked).to be(true)
        expect { migrate }.not_to(change { checklist.items.first.checked })
      end
    end

    context 'when checklist item is unchecked' do
      let(:checklist_item_checked) { false }

      it 'does not change the checklist item' do
        expect(checklist.items.first.checked).to be(false)
        expect { migrate }.not_to(change { checklist.items.first.checked })
      end
    end

  end

  context 'with a linked ticket' do
    context 'when ticket is closed' do
      let(:state_name) { 'closed' }

      context 'when checklist item is checked' do
        it 'does not change the checklist item' do
          expect(checklist.items.first.checked).to be(true)
          expect { migrate }.not_to(change { checklist.items.first.checked })
        end
      end

      context 'when checklist item is unchecked' do
        let(:checklist_item_checked) { false }

        it 'checks the item' do
          expect { migrate }.to change { checklist.items.first.checked }.from(false).to(true)
        end
      end

    end

    context 'when ticket is open' do
      context 'when checklist item is checked' do
        it 'unchecks the item' do
          expect { migrate }.to change { checklist.items.first.checked }.from(true).to(false)
        end
      end

      context 'when checklist item is unchecked' do
        let(:checklist_item_checked) { false }

        it 'does not change the checklist item' do
          expect(checklist.items.first.checked).to be(false)
          expect { migrate }.not_to(change { checklist.items.first.checked })
        end
      end
    end
  end
end
