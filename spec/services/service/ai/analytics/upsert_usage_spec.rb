# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Analytics::UpsertUsage do
  describe '#execute' do
    let(:user)             { create(:agent) }
    let(:ai_analytics_run) { create(:ai_analytics_run) }

    it 'creates a new usage if none exists' do
      usage = described_class
        .new(user, ai_analytics_run, rating: true)
        .execute

      expect(usage).to have_attributes(
        id:               be_present,
        user:,
        ai_analytics_run:,
        rating:           true,
        comment:          nil,
        context:          {}
      )
    end

    context 'when a usage already exists' do
      let(:usage) do
        create(:ai_analytics_usage,
               user:,
               ai_analytics_run:,
               rating:           true,
               context:          { initial: true, to_delete: true })
      end

      let(:upserted_usage) do
        described_class
          .new(other_user, ai_analytics_run, context: { additional: true, to_delete: nil })
          .execute
      end

      before { usage && upserted_usage }

      context 'when updating with the same user' do
        let(:other_user) { user }

        it 'keeps same usage' do
          expect(upserted_usage.id).to eq(usage.id)
        end

        it 'updates existing usage by the same user' do
          expect(upserted_usage).to have_attributes(
            id:               usage.id,
            user:,
            ai_analytics_run:,
            rating:           true,
            context:          { 'initial' => true, 'additional' => true }
          )
        end
      end

      context 'when updating with a different user' do
        let(:other_user) { create(:agent) }

        it 'creates a new usage for a different user' do
          expect(upserted_usage.id).not_to eq(usage.id)
        end

        it 'creates a new usage with new attributes' do
          expect(upserted_usage).to have_attributes(
            id:               be_present,
            user:             other_user,
            ai_analytics_run:,
            context:          { 'additional' => true }
          )
        end
      end
    end
  end
end
