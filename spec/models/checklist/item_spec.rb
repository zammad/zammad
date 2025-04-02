# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist::Item, :aggregate_failures, current_user_id: 1, type: :model do
  let(:ticket)    { create(:ticket) }
  let(:checklist) { create(:checklist, item_count: 0, ticket:) }

  describe '#validate_item_count' do
    let(:checklist_full) { create(:checklist, item_count: 100) }

    it 'does not allow more than 100 items' do
      next_item = build(:checklist_item, checklist: checklist_full)

      next_item.valid?

      expect(next_item.errors.full_messages)
        .to include('Checklist items are limited to 100 items per checklist.')
    end

    it 'does not run a check when cloning' do
      next_item = build(:checklist_item, checklist: checklist_full, initial_clone: true)

      next_item.valid?

      expect(next_item.errors).to be_blank
    end
  end

  describe '#detect_ticket_loop_reference' do
    it 'passes when another ticket is referenced' do
      item = create(:checklist_item, checklist:, ticket: create(:ticket))

      expect(item).to be_persisted
    end

    it 'fails when parent ticket is referenced' do
      item = build(:checklist_item, checklist:, ticket:).tap(&:save)

      expect(item.errors.messages_for(:ticket)).to include('reference must not be the checklist ticket.')
    end
  end

  describe '#detect_ticket_reference' do
    let(:target_ticket) { create(:ticket) }
    let(:number) do
      ticket_hook         = Setting.get('ticket_hook')
      ticket_hook_divider = Setting.get('ticket_hook_divider')

      "#{ticket_hook}#{ticket_hook_divider}#{target_ticket.number}"
    end

    it 'detects given ticket' do
      item = create(:checklist_item, checklist:, text: number)

      expect(item.ticket).to eq target_ticket
    end

    it 'skips detecting when using a template' do
      item = create(:checklist_item, checklist:, text: number, initial_clone: true)

      expect(item.ticket).to be_nil
    end

    it 'fails gracefully when non-existant number-like text is given' do
      item = create(:checklist_item, checklist:, text: "#{number}1")

      expect(item.ticket).to be_nil
    end
  end

  describe '#detect_ticket_reference_state' do
    let(:target_ticket) { create(:ticket) }

    it 'does not set ticket state if no ticket given' do
      target_ticket
      checklist

      allow(Checklist).to receive(:ticket_closed?)
      create(:checklist_item, checklist:)
      expect(Checklist).not_to have_received(:ticket_closed?)
    end

    it 'sets ticket state when setting a ticket' do
      allow(Checklist).to receive(:ticket_closed?)
      allow(Checklist).to receive(:ticket_closed?).with(target_ticket).and_return(true)
      item = create(:checklist_item, checklist:, ticket: target_ticket)
      expect(item).to be_checked
    end

    it 'does not set ticket state when setting another attribute' do
      item = create(:checklist_item, checklist:, ticket: target_ticket)
      allow(Checklist).to receive(:ticket_closed?)
      item.update!(text: 'another')
      expect(Checklist).not_to have_received(:ticket_closed?)
    end
  end

  describe '#update_checklist_on_destroy' do
    let(:item) { create(:checklist_item, checklist:) }

    before { item }

    it 'removes item from checklist sorted_item_ids when destroying' do
      expect { item.destroy! }
        .to change { checklist.reload.sorted_item_ids }
        .to be_blank
    end

    it 'works fine when parent checklist is destroyed' do
      expect { item.checklist.destroy! }.not_to raise_error
    end
  end

  describe '#update_checklist_on_save' do
    it 'adds the item to checklist sorted_item_ids' do
      item = create(:checklist_item, checklist:)

      expect(checklist.sorted_item_ids).to include(item.id.to_s)
    end

    it 'touches checklist when updating the item' do
      item = create(:checklist_item, checklist:)

      travel 10.minutes

      expect { item.update! checked: true }
        .to change { item.checklist.updated_at }
    end
  end

  describe '#update_referenced_ticket' do
    it 'touches referenced ticket' do
      target_ticket = create(:ticket)

      travel 10.minutes

      expect { create(:checklist_item, checklist:, ticket: target_ticket) }
        .to change { target_ticket.reload.updated_at }
    end

    it 'touches referenced ticket on destroying' do
      target_ticket = create(:ticket)
      item = create(:checklist_item, checklist:, ticket: target_ticket)

      travel 10.minutes

      expect { item.destroy! }
        .to change { target_ticket.reload.updated_at }
    end
  end

  describe '.incomplete' do
    it 'returns unchecked items' do
      unchecked = create(:checklist_item, checked: false, checklist:)
      create(:checklist_item, checked: true, checklist:)

      expect(described_class.incomplete).to contain_exactly(unchecked)
    end
  end

  describe 'history entries for checked' do
    let(:checklist) do
      create(:checklist, item_count: 1)
    end

    it 'creates history entries for checked' do
      checklist.items.first.update!(checked: true)

      history_type_id = History::Type.find_by(name: 'checklist_item_checked').id

      expect(History.last).to have_attributes(
        history_type_id: history_type_id,
        value_from:      checklist.items.first.text,
        value_to:        'true',
      )

      checklist.items.first.update!(checked: false)

      expect(History.last).to have_attributes(
        history_type_id: history_type_id,
        value_from:      checklist.items.first.text,
        value_to:        'false',
      )
    end
  end
end
