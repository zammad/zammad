# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::StoredResult, type: :model do
  subject(:result_storage) { create(:ai_stored_result) }

  it { is_expected.to validate_presence_of(:identifier) }
  it { is_expected.to belong_to(:locale).optional }
  it { is_expected.to belong_to(:related_object).optional }
  it { is_expected.to belong_to(:ai_analytics_run).optional }
  it { is_expected.to validate_uniqueness_of(:identifier).scoped_to(:locale_id, :related_object_type, :related_object_id) }

  describe 'identifier uniqueness check' do
    it 'allows single identifier without a related object' do
      expect(result_storage).to be_valid
    end

    it 'does not allow multiple identifiers without the related object' do
      result_storage

      record = build(:ai_stored_result, identifier: result_storage.identifier)

      expect(record).not_to be_valid
    end

    it 'allows identifier with both a related object and no related object' do
      record_a = create(:ai_stored_result, related_object: create(:ticket))
      record_b = build(:ai_stored_result, related_object: create(:ticket), identifier: record_a.identifier)

      expect(record_b).to be_valid
    end
  end

  describe '.cleanup' do
    let(:locale)   { Locale.first }
    let(:object)   { create(:ticket) }
    let(:record_a) { create(:ai_stored_result, created_at: 2.days.ago, locale:) }
    let(:record_b) { create(:ai_stored_result, created_at: 10.hours.ago, locale: Locale.second) }
    let(:record_c) { create(:ai_stored_result, created_at: 11.hours.ago, locale:, related_object: object) }

    before { record_a && record_b }

    context 'when diff is provided' do
      it 'deletes records older than the specified diff' do
        expect { described_class.cleanup(diff: 1.day) }
          .to change(described_class, :all).to [record_b, record_c]
      end
    end

    context 'when locale is provided' do
      it 'deletes records matching the specified locale' do
        expect { described_class.cleanup(locale:) }
          .to change(described_class, :all).to [record_b]
      end
    end

    context 'when object is provided' do
      it 'deletes records matching the specified object' do
        expect { described_class.cleanup(object:) }
          .to change(described_class, :all).to [record_a, record_b]
      end
    end

    context 'when no criteria are provided' do
      it 'deletes all records' do
        expect { described_class.cleanup }.to change(described_class, :all).to []
      end
    end
  end
end
