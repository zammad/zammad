# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist, :aggregate_failures, current_user_id: 1, type: :model do
  let(:ticket)    { create(:ticket) }
  let(:checklist) { create(:checklist, item_count: 0, ticket:) }

  describe 'validations' do
    context 'with valid attributes' do
      it 'succeeds creation' do
        expect(create(:checklist)).to be_persisted
      end
    end
  end

  describe '#complete' do
    it 'returns zero if list is empty' do
      expect(checklist.complete).to be_zero
    end

    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.complete).to be 3
    end
  end

  describe '#completed?' do
    it 'returns true if list is empty' do
      expect(checklist).to be_completed
    end

    it 'returns true if all completed' do
      create(:checklist_item, checklist:, checked: true)
      create(:checklist_item, checklist:, checked: true)

      expect(checklist).to be_completed
    end

    it 'returns false if some incomplete' do
      create(:checklist_item, checklist:, checked: true)
      create(:checklist_item, checklist:, checked: false)

      expect(checklist).not_to be_completed
    end
  end

  describe '#incomplete' do
    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.incomplete).to be 2
    end
  end

  describe '#total' do
    it 'returns count of completed items' do
      3.times { create(:checklist_item, checklist:, checked: true) }
      2.times { create(:checklist_item, checklist:, checked: false) }

      expect(checklist.total).to be 5
    end
  end

  describe '#update_ticket' do
    it 'touches ticket when updating the checklist' do
      checklist

      travel 10.minutes

      expect { checklist.update!(name: 'abc') }
        .to change { checklist.ticket.updated_at }
    end

    it 'touches ticket when destroying the checklist' do
      checklist

      travel 10.minutes

      expect { checklist.destroy! }
        .to change { checklist.ticket.updated_at }
    end

    it 'does not raise erorrs when ticket is destroyed' do
      checklist

      expect { checklist.ticket.destroy! }
        .not_to raise_error
    end
  end

  describe '.ticket_closed?' do
    it 'open ticket is not closed' do
      ticket = create(:ticket, state_name: 'open')
      expect(described_class).not_to be_ticket_closed(ticket)
    end

    it 'new ticket is not closed' do
      ticket = create(:ticket, state_name: 'new')
      expect(described_class).not_to be_ticket_closed(ticket)
    end

    it 'closed ticket is closed' do
      ticket = create(:ticket, state_name: 'closed')
      expect(described_class).to be_ticket_closed(ticket)
    end

    it 'merged ticket is closed' do
      ticket = create(:ticket, state_name: 'merged')
      expect(described_class).to be_ticket_closed(ticket)
    end
  end

  describe '.create_fresh!' do
    it 'creates a fresh checklist' do
      checklist = described_class.create_fresh!(ticket)

      expect(checklist.items).to contain_exactly(have_attributes(id: be_present, text: be_blank))
    end

    it 'does not create a checklist if the ticket already has one' do
      checklist

      expect { described_class.create_fresh!(ticket) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This ticket already has a checklist.'
        )
    end
  end

  describe '.create_from_template!' do
    let(:template) { create(:checklist_template) }

    it 'creates a checklist' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template).to be_persisted
    end

    it 'copies entries in order' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template.sorted_items.map(&:text)).to eq(template.items.map(&:text))
    end

    it 'copies entries with initial_clone flag' do
      checklist_from_template = described_class.create_from_template!(ticket, template)

      expect(checklist_from_template.items).to all(have_attributes(initial_clone: true))
    end

    it 'raises an error if template is inactive' do
      template.update! active: false

      expect { described_class.create_from_template!(ticket, template) }
        .to raise_error(
          Exceptions::UnprocessableEntity,
          'Checklist template must be active to use as a checklist starting point.'
        )
    end

    it 'does not create a checklist if the ticket already has one' do
      checklist

      expect { described_class.create_from_template!(ticket, template) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: This ticket already has a checklist.'
        )
    end
  end

  describe '.tickets_referencing' do
    let(:ticket)                 { create(:ticket, group:) }
    let(:other_ticket)           { create(:ticket, group:) }
    let(:inaccessible_ticket)    { create(:ticket) }
    let(:checklist)              { create(:checklist) }
    let(:other_checklist)        { create(:checklist) }
    let(:inaccessible_checklist) { create(:checklist, ticket: inaccessible_ticket) }
    let(:user)                   { create(:agent, groups: [group]) }
    let(:group)                  { create(:group) }

    before do
      other_checklist.items.create! ticket: other_ticket
    end

    it 'returns scope to work on' do
      expect(described_class.tickets_referencing(ticket)).to be_a(ActiveRecord::Relation)
    end

    it 'if user is given returns scope to work on' do
      expect(described_class.tickets_referencing(ticket, user)).to be_a(ActiveRecord::Relation)
    end

    context 'when ticket never referenced' do
      it 'returns 0 references' do
        expect(described_class.tickets_referencing(ticket)).to be_blank
      end
    end

    context 'when ticket is referenced' do
      before do
        checklist.items.create! ticket: ticket
      end

      it 'returns 1 reference' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket)
      end
    end

    context 'when ticket is referenced in multiple checklists' do
      before do
        checklist.items.create! ticket: ticket
        other_checklist.items.create! ticket: ticket
      end

      it 'returns 2 references' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket, other_checklist.ticket)
      end
    end

    context 'when ticket is referenced multiple times in the same checklist' do
      before do
        3.times { checklist.items.create! ticket: ticket }
      end

      it 'returns 2 references' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket)
      end
    end

    context 'with inaccessible reference' do
      before do
        checklist.update! ticket: other_ticket
        checklist.items.create! ticket: ticket
        inaccessible_checklist.items.create! ticket: ticket
      end

      it 'returns tickets accessible to given user only' do
        expect(described_class.tickets_referencing(ticket, user))
          .to contain_exactly(checklist.ticket)
      end

      it 'returns all tickets accessible if no user given' do
        expect(described_class.tickets_referencing(ticket))
          .to contain_exactly(checklist.ticket, inaccessible_checklist.ticket)
      end
    end
  end

  describe '.search_index_attribute_lookup' do
    subject(:checklist) { create(:checklist, name: 'some name') }

    it 'verify name attribute' do
      expect(checklist.search_index_attribute_lookup['name']).to eq checklist.name
    end

    it 'verify items attribute' do
      expect(checklist.search_index_attribute_lookup['items']).not_to eq []
    end

    it 'verify items[0].count' do
      expect(checklist.search_index_attribute_lookup['items'].count).to eq checklist.items.count
    end

    it 'verify items[0].text attribute' do
      expect(checklist.search_index_attribute_lookup['items'][0]['text']).to eq checklist.items[0].text
    end
  end

end
