# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::AIAnalytics::Usage, :aggregate_failures, type: :graphql do
  context 'when accessing as an agent', authenticated_as: :agent do
    let(:group)            { create(:group) }
    let(:agent)            { create(:agent, groups: [group]) }
    let(:ai_analytics_run) { create(:ai_analytics_run) }
    let(:rating)           { nil }
    let(:comment)          { nil }
    let(:context)          { nil }

    let(:query) do
      <<~MUTATION
        mutation aiAnalyticsUsage(
          $aiAnalyticsRunId: ID!
          $input: AIAnalyticsUsageInput!
        ) {
          aiAnalyticsUsage(
            aiAnalyticsRunId: $aiAnalyticsRunId
            input: $input
          ) {
            usage {
              id
            }
          }
        }
      MUTATION
    end

    let(:variables) do
      {
        aiAnalyticsRunId: gql.id(ai_analytics_run),
        input:            {
          rating:  rating,
          comment: comment,
          context: context,
        },
      }
    end

    before do
      usage if defined?(usage)

      gql.execute(query, variables: variables)
    end

    context 'with appropriate permissions' do
      let(:ticket)           { create(:ticket, group:) }
      let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }

      it 'records usage' do
        expect(gql.result.data['usage']['id']).to eq(gql.id(AI::Analytics::Usage.last))
      end

      context 'with an existing usage' do
        let(:usage) { create(:ai_analytics_usage, ai_analytics_run:, user: agent) }

        context 'with a rating' do
          let(:rating) { true }

          it 'updates the usage rating' do
            expect(gql.result.data['usage']['id']).to eq(gql.id(usage))
            expect(usage.reload.rating).to eq(rating)
          end
        end

        context 'with a comment' do
          let(:comment) { Faker::Lorem.unique.sentence }

          it 'updates the usage comment' do
            expect(gql.result.data['usage']['id']).to eq(gql.id(usage))
            expect(usage.reload.comment).to eq(comment)
          end
        end

        context 'with a usage context' do
          let(:context) { { approved: true } }

          it 'updates the usage context' do
            expect(gql.result.data['usage']['id']).to eq(gql.id(usage))
            expect(usage.reload.context).to eq(context.deep_stringify_keys)
          end
        end
      end
    end

    context 'without appropriate permissions' do
      let(:ticket)           { create(:ticket, group: create(:group)) }
      let(:ai_analytics_run) { create(:ai_analytics_run, related_object: ticket) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
