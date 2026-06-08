# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Analytics::UpsertUsage do
  describe '#execute' do
    subject(:service_result) do
      described_class
        .with_current_user(current_user)
        .execute(ai_analytics_run, rating: true, context: execute_context)
    end

    let(:user)             { create(:agent) }
    let(:ai_analytics_run) { create(:ai_analytics_run) }
    let(:current_user)     { user }
    let(:execute_context)  { {} }

    it 'creates a new usage if none exists' do
      expect(service_result).to have_attributes(
        id:               be_present,
        user:,
        ai_analytics_run:,
        rating:           true,
        comment:          nil,
        context:          {}
      )
    end

    context 'when a usage already exists' do
      let(:existing_usage) do
        create(:ai_analytics_usage,
               user:,
               ai_analytics_run:,
               rating:           true,
               context:          { initial: true, to_delete: true })
      end
      let(:execute_context) { { additional: true, to_delete: nil } }

      before { existing_usage }

      context 'when updating with the same user' do
        it 'keeps same usage' do
          expect(service_result.id).to eq(existing_usage.id)
        end

        it 'updates existing usage by the same user' do
          expect(service_result).to have_attributes(
            id:               existing_usage.id,
            user:,
            ai_analytics_run:,
            rating:           true,
            context:          { 'initial' => true, 'additional' => true }
          )
        end
      end

      context 'when updating with a different user' do
        let(:other_user)   { create(:agent) }
        let(:current_user) { other_user }

        it 'creates a new usage for a different user' do
          expect(service_result.id).not_to eq(existing_usage.id)
        end

        it 'creates a new usage with new attributes' do
          expect(service_result).to have_attributes(
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
