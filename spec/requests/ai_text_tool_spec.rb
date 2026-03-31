# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::TextTool', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  describe '#index' do
    it 'returns a list of AI text tools' do
      create(:ai_text_tool, name: 'Summarizer')
      create(:ai_text_tool, name: 'Rewriter')

      get '/api/v1/ai_text_tools', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include(
        include('name' => 'Summarizer'),
        include('name' => 'Rewriter')
      )
    end

    context 'with satisfaction ratio data' do
      let(:rated_tool)        { create(:ai_text_tool, name: 'Rated Tool') }
      let(:rated_tool_assets) { json_response.dig('assets', 'AITextTool', rated_tool.id.to_s) }
      let(:expected_result) do
        { positive: { count: 10, ratio: 50.0 }, negative: { count: 5, ratio: 25.0 }, neutral: { count: 5, ratio: 25.0 } }
      end

      before do
        allow(Service::AI::Analytics::AggregateSatisfactionRatio)
          .to receive_message_chain(:new, :execute) { expected_result } # rubocop:disable RSpec/MessageChain
      end

      it 'includes correct satisfaction_ratio for every tool' do
        rated_tool

        get '/api/v1/ai_text_tools?full=true', as: :json

        expect(rated_tool_assets[AI::TextTool::ASSETS_ANALYTICS_STATS_KEY]).to eq(expected_result.deep_stringify_keys)
      end

      context 'when user is not admin' do
        let(:user) { create(:agent) }

        it 'returns forbidden (no asset payload; controller requires admin.ai_assistance_text_tools)' do
          get '/api/v1/ai_text_tools?full=true', as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe '#show' do
    it 'returns a specific AI text tool' do
      ai_text_tool = create(:ai_text_tool, name: 'Summarizer')

      get "/api/v1/ai_text_tools/#{ai_text_tool.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => ai_text_tool.id, 'name' => 'Summarizer')
    end
  end

  describe '#create' do
    it 'creates a new AI text tool' do
      post '/api/v1/ai_text_tools', params: { name: 'New Text Tool' }, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('name' => 'New Text Tool')
    end
  end

  describe '#update' do
    it 'updates an existing AI text tool' do
      ai_text_tool = create(:ai_text_tool, name: 'Old Text Tool')

      put "/api/v1/ai_text_tools/#{ai_text_tool.id}", params: { name: 'Updated Text Tool' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('name' => 'Updated Text Tool')
    end
  end

  describe '#search' do
    it 'searches for AI text tools' do
      create(:ai_text_tool, name: 'Searchable Text Tool 1')
      create(:ai_text_tool, name: 'Text Tool 2')

      get '/api/v1/ai_text_tools/search', params: { query: 'Searchable' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to contain_exactly(
        include('name' => 'Searchable Text Tool 1'),
      )
    end
  end

  describe '#destroy' do
    it 'deletes an AI text tool' do
      ai_text_tool = create(:ai_text_tool, name: 'Text Tool to Delete')

      delete "/api/v1/ai_text_tools/#{ai_text_tool.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect { AI::TextTool.find(ai_text_tool.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#reset_analytics' do
    def call_reset_endpoint(id)
      put "/api/v1/ai_text_tools/#{id}/reset_analytics", as: :json
    end

    def expect_json_success_response
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq('success' => true)
    end

    let(:ai_text_tool) { create(:ai_text_tool, name: 'Text Tool with Analytics') }

    context 'when user is admin' do
      it 'resets analytics_stats_reset_at timestamp' do
        expect { call_reset_endpoint(ai_text_tool.id) }
          .to change { ai_text_tool.reload.analytics_stats_reset_at }
          .from(nil)
          .to be_within(1.second).of(Time.zone.now)

        expect_json_success_response
      end

      it 'returns 404 for non-existing id' do
        call_reset_endpoint(999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not admin' do
      let(:user) { create(:agent) }

      it 'returns 403 Forbidden' do
        call_reset_endpoint(ai_text_tool.id)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
