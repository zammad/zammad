# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist, :aggregate_failures, current_user_id: 1, type: :model do
  describe 'validations' do
    context 'when referenced ticket does not exist' do
      it 'fails validation with an error' do
        expect { create(:checklist, ticket_id: Ticket.maximum(:id).next) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with valid attributes' do
      it 'succeeds creation' do
        expect(create(:checklist)).to be_persisted
      end
    end

    context 'when limits are reached' do
      it 'does not allow more than 100 items' do
        checklist = create(:checklist, item_count: 100)
        expect { checklist.items.create!(text: 'new') }
          .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Checklist items are limited to 100 items per checklist.')
      end
    end
  end

  describe 'complete status' do
    let(:checklist) do
      list = create(:checklist, item_count: 3)
      list.items.first.update!(checked: true)

      list
    end

    context 'when any item is incomplete' do
      it '#completed? returns false' do
        expect(checklist.completed?).to be false
      end

      it '#incomplete returns the count of incomplete items' do
        expect(checklist.incomplete).to eq 2
      end

      it '#complete returns the count of complete items' do
        expect(checklist.complete).to eq 1
      end

      it '#total returns the count of all items' do
        expect(checklist.total).to eq 3
      end
    end

    context 'when all items are complete' do
      before do
        checklist.items.each { |item| item.update!(checked: true) }
      end

      it '#completed? returns true' do
        expect(checklist.completed?).to be true
      end

      it '#incomplete returns the count of incomplete items' do
        expect(checklist.incomplete).to eq 0
      end

      it '#complete returns the count of complete items' do
        expect(checklist.complete).to eq 3
      end

      it '#total returns the count of all items' do
        expect(checklist.total).to eq 3
      end
    end

    context 'when no items are present' do
      before do
        checklist.items.destroy_all
      end

      it '#completed? returns true' do
        expect(checklist.completed?).to be true
      end

      it '#incomplete returns the count of incomplete items' do
        expect(checklist.incomplete).to eq 0
      end

      it '#complete returns the count of complete items' do
        expect(checklist.complete).to eq 0
      end

      it '#total returns the count of all items' do
        expect(checklist.total).to eq 0
      end
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
end
