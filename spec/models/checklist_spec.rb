# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Checklist, :aggregate_failures, type: :model do
  describe 'validations' do
    let(:attributes) do
      {
        name:          'Checklist',
        ticket_id:     1,
        created_by_id: 1,
        updated_by_id: 1
      }
    end

    context 'when required attributes are missing' do
      {
        name:          ActiveRecord::NotNullViolation,
        ticket_id:     ActiveRecord::RecordInvalid,
        created_by_id: ActiveRecord::RecordInvalid,
        updated_by_id: ActiveRecord::RecordInvalid
      }.each do |attribute, error|
        it "fails validation with missing #{attribute}" do
          attributes.delete(attribute)

          expect { described_class.create!(attributes) }.to raise_error(error)
        end
      end
    end

    context 'when referenced ticket does not exist' do
      it 'fails validation with an error' do
        attributes[:ticket_id] = 2

        expect { described_class.create!(attributes) }.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    context 'with valid attributes' do
      it 'succeeds creation' do
        expect(described_class.create!(attributes)).to be_valid
      end
    end

    context 'when limits are reached' do
      it 'does not allow more than 100 items' do
        checklist = create(:checklist, item_count: 100)
        expect { checklist.items.create!(text: 'new', created_by_id: 1, updated_by_id: 1) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Checklist items are limited to 100 items per checklist.')
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
    end
  end
end
