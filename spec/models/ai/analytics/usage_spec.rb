# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::Analytics::Usage, type: :model do
  subject(:ai_analytics_usage) { create(:ai_analytics_usage) }

  it 'has a valid factory' do
    expect(ai_analytics_usage).to be_valid
  end

  it { is_expected.to belong_to(:ai_analytics_run).class_name('AI::Analytics::Run') }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_uniqueness_of(:ai_analytics_run_id).scoped_to(:user_id) }

  describe '#validate_rating_changing' do
    context 'when creating a new usage entry' do
      it 'allows setting the rating' do
        usage = build(:ai_analytics_usage, rating: true)
        expect(usage).to be_valid
      end

      it 'allows not setting the rating' do
        usage = build(:ai_analytics_usage, rating: nil)
        expect(usage).to be_valid
      end
    end

    context 'when updating an existing usage entry' do
      context 'when no rating is set' do
        let(:ai_analytics_usage) { create(:ai_analytics_usage, rating: nil) }

        it 'allows setting the rating' do
          ai_analytics_usage.rating = true
          expect(ai_analytics_usage).to be_valid
        end

        it 'allows not setting the rating' do
          ai_analytics_usage
          expect(ai_analytics_usage).to be_valid
        end
      end

      context 'when rating is already set' do
        let(:ai_analytics_usage) { create(:ai_analytics_usage, rating: true) }

        it 'disallows changing the rating' do
          ai_analytics_usage.rating = false
          ai_analytics_usage.valid?
          expect(ai_analytics_usage.errors[:base]).to include('Rating can only be set once')
        end

        it 'disallows unsetting the rating' do
          ai_analytics_usage.rating = nil
          ai_analytics_usage.valid?
          expect(ai_analytics_usage.errors[:base]).to include('Rating can only be set once')
        end
      end
    end
  end
end
