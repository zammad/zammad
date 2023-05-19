# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'rotp'

RSpec.describe 'User', performs_jobs: true, type: :request do
  let(:agent)              { create(:agent) }
  let(:admin)              { create(:admin) }
  let(:two_factor_pref)    { create(:'user/two_factor_preference', user: agent) }
  let(:two_factor_enabled) { true }

  before do |example|
    Setting.set('two_factor_authentication_method_authenticator_app', two_factor_enabled)
    two_factor_pref

    if example.metadata[:as] == :admin
      action_user = admin
      permissions = %w[admin.user]
    else
      action_user = agent
      permissions = %w[ticket.agent]
    end

    authenticated_as(action_user, token: create(:token, user: action_user, permissions: permissions))
  end

  describe 'DELETE /users/:id/two_factor_remove_method' do
    context 'when agent' do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_method", params: { method: 'authenticator_app' }, as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when admin', as: :admin do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_method", params: { method: 'authenticator_app' }, as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE /users/:id/two_factor_remove_all_methods' do
    context 'when agent' do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_all_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when admin', as: :admin do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_all_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET /users/two_factor_enabled_methods' do
    context 'with disabled authenticator app method' do
      let(:two_factor_enabled) { false }
      let(:two_factor_pref)    { nil }

      it 'returns nothing', :aggregate_failures do
        get "/api/v1/users/#{agent.id}/two_factor_enabled_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_blank
      end
    end

    context 'with not having authenticator app configured' do
      let(:two_factor_pref) { nil }

      it 'returns the correct result', :aggregate_failures do
        get "/api/v1/users/#{agent.id}/two_factor_enabled_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.first).to eq({
                                            'method'     => 'authenticator_app',
                                            'configured' => false,
                                            'default'    => false,
                                          })
      end
    end

    context 'with having authenticator app configured' do
      it 'returns the correct result', :aggregate_failures do
        get "/api/v1/users/#{agent.id}/two_factor_enabled_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response.first).to eq({
                                            'method'     => 'authenticator_app',
                                            'configured' => true,
                                            'default'    => true,
                                          })
      end
    end
  end

  describe 'POST /users/two_factor_verify_configuration' do
    let(:two_factor_pref)   { nil }
    let(:params)            { {} }
    let(:method)            { 'authenticator_app' }
    let(:verification_code) { ROTP::TOTP.new(configuration[:secret]).now }
    let(:configuration)     { agent.auth_two_factor.method_object(method).configuration_options }

    before do
      post '/api/v1/users/two_factor_verify_configuration', params: params, as: :json
    end

    it 'fails without needed params' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'with needed params' do
      let(:params) do
        {
          method:        method,
          payload:       verification_code,
          configuration: configuration,
        }
      end

      context 'with wrong verification code' do
        let(:verification_code) { 'wrong' }

        it 'verified is false' do
          expect(json_response['verified']).to be(false)
        end
      end

      context 'with correct verification code' do
        it 'verified is true' do
          expect(json_response['verified']).to be(true)
        end
      end
    end
  end

  describe 'GET /users/two_factor_method_configuration/:method' do
    let(:two_factor_pref)   { nil }
    let(:method)            { 'authenticator_app' }

    before do
      get "/api/v1/users/two_factor_method_configuration/#{method}", as: :json
    end

    context 'with invalid params' do
      context 'with an unknown method' do
        let(:method) { 'unknown' }

        it 'fails' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'with valid params' do
      it 'returns configuration', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response['configuration']).to include('secret').and include('provisioning_uri')
      end
    end
  end
end
