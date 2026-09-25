# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Analytics::UpsertUsage, :aggregate_failures do
  describe '#execute' do
    subject(:service_result) do
      described_class
        .with_current_user(current_user)
        .execute(ai_analytics_run, **execute_args)
    end

    let(:user)             { create(:agent) }
    let(:ai_analytics_run) { create(:ai_analytics_run) }
    let(:current_user)     { user }
    let(:execute_args)     { { rating: true, context: {} } }

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
               rating:           existing_rating,
               comment:          existing_comment,
               context:          { initial: true, to_delete: true })
      end
      let(:existing_rating)  { nil }
      let(:existing_comment) { nil }
      let(:execute_args)     { { rating: true, context: { additional: true, to_delete: nil } } }

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
        let(:existing_rating) { false }
        let(:other_user)      { create(:agent) }
        let(:current_user)    { other_user }

        it 'creates a new usage for a different user' do
          expect(service_result.id).not_to eq(existing_usage.id)
        end

        it 'creates a new usage with new attributes' do
          expect(service_result).to have_attributes(
            id:               be_present,
            user:             other_user,
            ai_analytics_run:,
            rating:           true,
            context:          { 'additional' => true }
          )
        end
      end

      context 'when the usage is rated already' do
        let(:existing_rating) { false }

        shared_examples 'rejecting the feedback' do
          it 'raises an error and keeps the usage' do
            expect { service_result }.to raise_error(described_class::FeedbackAlreadyProvidedError)
            expect(existing_usage.reload).to have_attributes(rating: false, comment: existing_comment, context: { 'initial' => true, 'to_delete' => true })
          end
        end

        context 'with the same rating' do
          let(:execute_args) { { rating: false } }

          it_behaves_like 'rejecting the feedback'
        end

        context 'with a different rating' do
          let(:execute_args) { { rating: true } }

          it_behaves_like 'rejecting the feedback'
        end

        context 'with a comment' do
          let(:execute_args) { { comment: 'Missed the point.' } }

          it 'adds the comment' do
            expect(service_result).to have_attributes(rating: false, comment: 'Missed the point.')
          end
        end

        context 'with a comment when one is stored already' do
          let(:existing_comment) { 'First comment.' }
          let(:execute_args)     { { comment: 'Second comment.' } }

          it_behaves_like 'rejecting the feedback'
        end

        context 'with a usage context only' do
          let(:execute_args) { { context: { approved: true } } }

          it 'updates the usage context' do
            expect(service_result.context).to eq({ 'initial' => true, 'to_delete' => true, 'approved' => true })
          end
        end

        context 'without any attributes' do
          let(:execute_args) { {} }

          it 'keeps the usage' do
            expect(service_result).to have_attributes(id: existing_usage.id, rating: false)
          end
        end
      end
    end
  end
end
