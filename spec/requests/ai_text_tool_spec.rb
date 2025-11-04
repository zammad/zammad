# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
end
