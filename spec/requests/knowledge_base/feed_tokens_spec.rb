# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase::FeedTokens', authenticated_as: :user, type: :request do
  let(:endpoint) { '/api/v1/knowledge_bases/feed_tokens' }
  let(:user)     { create(:admin) }
  let(:token)    { create(:token, action: 'KnowledgeBaseFeed', user: user) }

  describe '#show' do
    it 'returns token when it exists' do
      token

      get endpoint

      expect(json_response['token']).to eq(token.name)
    end

    it 'created and returns token' do
      get endpoint

      expect(json_response['token']).to be_present
    end

    it 'creates a persistent token' do
      get endpoint

      expect(Token.find_by(action: 'KnowledgeBaseFeed')).to be_persistent
    end
  end

  describe '#update' do
    it 'changes token when it exists' do
      token

      expect { patch(endpoint) }.to change { token.reload.name }
    end

    it 'created and returns token' do
      patch endpoint

      expect(json_response['token']).to be_present
    end

    it 'creates a persistent token' do
      get endpoint

      expect(Token.find_by(action: 'KnowledgeBaseFeed')).to be_persistent
    end
  end
end
