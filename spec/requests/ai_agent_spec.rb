# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI::Agent', :aggregate_failures, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  describe '#index' do
    it 'returns a list of AI agents' do
      create(:ai_agent, name: 'Test AI Agent 1')
      create(:ai_agent, name: 'Test AI Agent 2')

      get '/api/v1/ai_agents', as: :json

      expect(response).to have_http_status(:ok)

      expect(json_response).to contain_exactly(
        include('name' => 'Test AI Agent 1'),
        include('name' => 'Test AI Agent 2')
      )
    end
  end

  describe '#show' do
    it 'returns a specific AI agent' do
      ai_agent = create(:ai_agent, name: 'Test AI Agent')

      get "/api/v1/ai_agents/#{ai_agent.id}", as: :json

      expect(response).to have_http_status(:ok)

      expect(json_response).to include('id' => ai_agent.id, 'name' => 'Test AI Agent')
    end

    context 'when full assets are requested' do
      it 'returns the AI agent with assets' do
        ai_agent = create(:ai_agent, name: 'Test AI Agent with Assets')
        create(:trigger, perform: { 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id } })
        create(:job, perform: { 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id } })

        get "/api/v1/ai_agents/#{ai_agent.id}?full=true", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('assets' => have_key('AIAgent').and(have_key('Trigger')))
      end
    end
  end

  describe '#create' do
    it 'creates a new AI agent' do
      post '/api/v1/ai_agents', params: { name: 'New AI Agent' }, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response).to include('name' => 'New AI Agent')
    end
  end

  describe '#update' do
    it 'updates an existing AI agent' do
      ai_agent = create(:ai_agent, name: 'Old AI Agent')

      put "/api/v1/ai_agents/#{ai_agent.id}", params: { name: 'Updated AI Agent' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('name' => 'Updated AI Agent')
    end
  end

  describe '#search' do
    it 'searches for AI agents' do
      create(:ai_agent, name: 'Searchable AI Agent 1')
      create(:ai_agent, name: 'AI Agent 2')

      get '/api/v1/ai_agents/search', params: { query: 'Searchable' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to contain_exactly(
        include('name' => 'Searchable AI Agent 1'),
      )
    end
  end

  describe '#destroy' do
    it 'deletes an AI agent' do
      ai_agent = create(:ai_agent, name: 'AI Agent to Delete')

      delete "/api/v1/ai_agents/#{ai_agent.id}", as: :json

      expect(response).to have_http_status(:ok)
      expect { AI::Agent.find(ai_agent.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns an error if the AI agent has references' do
      ai_agent = create(:ai_agent, name: 'AI Agent with References')

      trigger = create(:trigger, perform: { 'ai.ai_agent' => { 'ai_agent_id' => ai_agent.id } })

      delete "/api/v1/ai_agents/#{ai_agent.id}", as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('This object is referenced by other object(s) and thus cannot be deleted: %s')
      expect(json_response['unprocessable_entity']).to include("Trigger / #{trigger.name} (##{trigger.id})")
    end
  end

  describe '#types' do
    it 'returns available AI agent types' do
      get '/api/v1/ai_agents/types', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
        .and include(**AI::Agent::Type::TicketGroupDispatcher.new.data.deep_stringify_keys)
    end
  end
end
