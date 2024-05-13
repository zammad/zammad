# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User Access token', authenticated_as: :user, type: :request do
  let(:user)          { create(:agent) }
  let(:token)         { create(:token, user: user) }
  let(:another_token) { create(:token) }

  before do
    token && another_token
  end

  describe 'GET /user_access_token' do
    it 'returns user tokens and permissions' do
      get '/api/v1/user_access_token'

      expect(json_response)
        .to include(
          'tokens'      => contain_exactly(include('id' => token.id)),
          'permissions' => include(
            include('name' => 'ticket.agent'),
            include('name' => 'user_preferences'),
          )
        )
    end

    it 'uses tokens list service', aggregate_failures: true do
      allow(Service::User::AccessToken::List)
        .to receive(:new)
        .and_call_original

      expect_any_instance_of(Service::User::AccessToken::List)
        .to receive(:execute)
        .and_call_original

      get '/api/v1/user_access_token'

      expect(Service::User::AccessToken::List)
        .to have_received(:new)
    end
  end

  describe 'POST /user_access_token' do
    before { Setting.set('api_token_access', enabled) }

    context 'when token access is enabled' do
      let(:enabled) { true }

      it 'checks if name is present' do
        post '/api/v1/user_access_token', params: { name: '', permission: %w[ticket.agent] }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns token value' do
        post '/api/v1/user_access_token', params: { name: 'test', permission: %w[ticket.agent] }, as: :json

        expect(json_response).to eq('token' => Token.last.token)
      end

      it 'users token create service', aggregate_failures: true do
        allow(Service::User::AccessToken::Create)
          .to receive(:new)
          .and_call_original

        expect_any_instance_of(Service::User::AccessToken::Create)
          .to receive(:execute)
          .and_call_original

        post '/api/v1/user_access_token', params: { name: 'test', permission: %w[ticket.agent] }, as: :json

        expect(Service::User::AccessToken::Create)
          .to have_received(:new)
      end
    end

    context 'when token access is disabled' do
      let(:enabled) { false }

      it 'throws error' do
        post '/api/v1/user_access_token', params: {}, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /user_access_token' do
    it 'deletes token' do
      expect { delete "/api/v1/user_access_token/#{token.id}", as: :json }
        .to change { Token.exists? token.id }
        .to false
    end

    it 'raises error if token is owned by another user' do
      expect { delete "/api/v1/user_access_token/#{another_token.id}", as: :json }
        .not_to change { Token.exists? token.id }
        .from true
    end
  end
end
