# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RemoveDuplicateTranslations, type: :db_migration do

  def create_translation(attributes)
    Translation.new(attributes.merge({ locale: 'de-de', created_by_id: 1, updated_by_id: 1 })).tap(&:save!)
  end

  context 'when having unsynchronized entries with duplicates' do
    let!(:unrelated_entry_one)   { create_translation({ source: 'unknown entry', target: 'unknown translation', is_synchronized_from_codebase: false }) }
    let!(:unrelated_entry_two)   { create_translation({ source: 'unknown entry', target: 'unknown translation', is_synchronized_from_codebase: false }) }
    let!(:unrelated_entry_three) { create_translation({ source: 'unknown entry', target: 'unknown translation', is_synchronized_from_codebase: false }) }

    before do
      migrate
    end

    it 'does not delete the first' do
      expect(unrelated_entry_one.reload).to be_present
    end

    it 'deletes the second' do
      expect { unrelated_entry_two.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'deletes the third' do
      expect { unrelated_entry_three.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when having multiple duplicate records of existing synchronized records' do
    # 'yes': 'ja' already exists as synchronized entry in the translations for 'de-de'.
    let!(:duplicate_one) { create_translation({ source: 'yes', target: 'ja', is_synchronized_from_codebase: false }) }
    let!(:duplicate_two) { create_translation({ source: 'yes', target: 'ja', is_synchronized_from_codebase: false }) }

    before do
      migrate
    end

    it 'deletes the first' do
      expect { duplicate_one.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'deletes the second' do
      expect { duplicate_two.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'keeps the original' do
      expect(Translation.where(locale: 'de-de', source: 'yes').count { |e| e.source == 'yes' }).to eq(1)
    end
  end

  context 'when no duplicates are present' do
    it 'does nothing' do
      expect { migrate }.not_to change(Translation, :count)
    end
  end
end
