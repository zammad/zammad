# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::Analytics::UsageController', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  describe '#update' do
    let(:ai_analytics_run) { create(:ai_analytics_run, related_object: nil) }

    before do
      allow(Service::AI::Analytics::UpsertUsage).to receive(:new).and_call_original
      allow_any_instance_of(Service::AI::Analytics::UpsertUsage).to receive(:execute).and_return(true)

      put '/api/v1/ai/analytics/usages', params:, as: :json
    end

    context 'when submitting rating' do
      let(:params) { { ai_analytics_run_id: ai_analytics_run.id, rating: true } }

      it 'response is success' do
        expect(response).to have_http_status(:ok)
      end

      it 'passes correct arguments to service' do
        expect(Service::AI::Analytics::UpsertUsage)
          .to have_received(:new)
          .with(user, ai_analytics_run, rating: true)
      end
    end

    context 'when submitting rating and comments' do
      let(:params) { { ai_analytics_run_id: ai_analytics_run.id, comment: 'Comment here' } }

      it 'response is success' do
        expect(response).to have_http_status(:ok)
      end

      it 'passes correct arguments to service' do
        expect(Service::AI::Analytics::UpsertUsage)
          .to have_received(:new)
          .with(user, ai_analytics_run, comment: 'Comment here')
      end
    end

    context 'when submitting context' do
      let(:params) { { ai_analytics_run_id: ai_analytics_run.id, rating: false, context: { approved: false } } }

      it 'response is success' do
        expect(response).to have_http_status(:ok)
      end

      it 'passes correct arguments to service' do
        expect(Service::AI::Analytics::UpsertUsage)
          .to have_received(:new)
          .with(user, ai_analytics_run, rating: false, context: { approved: false })
      end
    end
  end
end
