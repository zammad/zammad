# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Analytics::AggregateSatisfactionRatio do
  describe '#execute' do
    subject(:result) { described_class.new(triggered_by: tool).execute }

    let(:tool) { create(:ai_text_tool) }

    def create_run_with_usage(tool:, created_at: nil, ratings: [], usage_created_at: nil)
      run = create(:ai_analytics_run, triggered_by: tool, created_at:)
      ratings.each do |rating|
        create(:ai_analytics_usage, ai_analytics_run: run, rating:, created_at: usage_created_at)
      end
      run
    end

    context 'when a tool has no runs' do
      it 'returns empty ratios for the tool' do
        expect(result).to eq hash_for_counts(positive: [0, 0], negative: [0, 0], neutral: [0, 0])
      end
    end

    context 'when runs and ratings exist' do
      before do
        create_run_with_usage(tool:, ratings: [true, nil])
        create_run_with_usage(tool:, ratings: [false])
      end

      it 'aggregates positive, negative, neutral and total' do
        expect(result).to eq hash_for_counts(positive: [1, 33.33], negative: [1, 33.33], neutral: [1, 33.33])
      end
    end

    context 'when runs and ratings exist from multiple objects' do
      before do
        create_run_with_usage(tool:, ratings: [true, nil])
        create_run_with_usage(tool: create(:ai_text_tool), ratings: [false])
      end

      it 'aggregates positive, negative, neutral and total' do
        expect(result).to eq hash_for_counts(positive: [1, 50.0], negative: [0, 0.0], neutral: [1, 50.0])
      end
    end

    context 'when analytics_stats_reset_at is present' do
      before do
        tool.update!(analytics_stats_reset_at: 6.hours.ago)
        # old run, old feedback => excluded
        create_run_with_usage(
          tool:             tool,
          created_at:       2.days.ago,
          ratings:          [true],
          usage_created_at: 2.days.ago
        )
        # old run, new feedback => included (filters by usage.created_at)
        create_run_with_usage(
          tool:             tool,
          created_at:       2.days.ago,
          ratings:          [false, nil],
          usage_created_at: 1.hour.ago
        )
      end

      it 'counts only feedback created after reset_at' do
        expect(result).to eq hash_for_counts(positive: [0, 0.0], negative: [1, 50.0], neutral: [1, 50.0])
      end
    end
  end

  def hash_for_counts(positive:, negative:, neutral:)
    {
      positive: { count: positive[0], percent: positive[1] },
      negative: { count: negative[0], percent: negative[1] },
      neutral:  { count: neutral[0], percent: neutral[1] },
      total:    [positive, negative, neutral].sum(&:first),
    }
  end
end
