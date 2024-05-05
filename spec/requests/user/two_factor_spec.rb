# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User', current_user_id: 1, performs_jobs: true, type: :request do
  let(:agent)              { create(:agent) }
  let(:admin)              { create(:admin) }
  let(:two_factor_pref)    { create(:user_two_factor_preference, :authenticator_app, user: agent) }
  let(:two_factor_enabled) { true }

  before do |example|
    Setting.set('two_factor_authentication_method_authenticator_app', two_factor_enabled)
    two_factor_pref

    if example.metadata[:as] == :admin
      action_user = admin
      permissions = %w[admin.user]
    else
      action_user = agent
      permissions = %w[user_preferences.two_factor_authentication]
    end

    authenticated_as(action_user, token: create(:token, user: action_user, permissions: permissions))
  end

  describe 'DELETE /users/:id/two_factor_remove_authentication_method' do
    context 'when agent' do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_authentication_method", params: { method: 'authenticator_app' }, as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when admin', as: :admin do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_authentication_method", params: { method: 'authenticator_app' }, as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE /users/:id/two_factor_remove_all_authentication_methods' do
    context 'when agent' do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_all_authentication_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with disabled method' do
        let(:other_two_factor_pref) { create(:user_two_factor_preference, :security_keys, user: agent) }

        before { other_two_factor_pref }

        it 'removes all methods', :aggregate_failures do
          expect { delete "/api/v1/users/#{agent.id}/two_factor_remove_all_authentication_methods", as: :json }
            .to change { agent.two_factor_preferences.exists? }
            .to false
        end
      end
    end

    context 'when admin', as: :admin do
      it 'gets the result', :aggregate_failures do
        delete "/api/v1/users/#{agent.id}/two_factor_remove_all_authentication_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect { two_factor_pref.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET /users/two_factor_enabled_authentication_methods' do
    context 'with disabled authenticator app method' do
      let(:two_factor_enabled) { false }
      let(:two_factor_pref)    { nil }

      it 'returns nothing', :aggregate_failures do
        get "/api/v1/users/#{agent.id}/two_factor_enabled_authentication_methods", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response).to be_blank
      end
    end

    context 'with not having authenticator app configured' do
      let(:two_factor_pref) { nil }

      it 'returns the correct result', :aggregate_failures do
        get "/api/v1/users/#{agent.id}/two_factor_enabled_authentication_methods", as: :json

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
        get "/api/v1/users/#{agent.id}/two_factor_enabled_authentication_methods", as: :json

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
    let(:recover_codes_enabled) { true }
    let(:has_recovery_codes)    { false }
    let(:two_factor_pref)       { nil }
    let(:params)                { {} }
    let(:method)                { 'authenticator_app' }
    let(:verification_code)     { ROTP::TOTP.new(configuration[:secret]).now }
    let(:configuration)         { agent.auth_two_factor.authentication_method_object(method).initiate_configuration }

    before do
      if has_recovery_codes
        create(:user_two_factor_preference, :recovery_codes, user: agent)
      end

      Setting.set('two_factor_authentication_recovery_codes', recover_codes_enabled)
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

      context 'with correct verification code', :aggregate_failures do
        it 'verified is true' do
          expect(json_response['verified']).to be(true)
          expect(json_response['recovery_codes'].length).to eq(10)
        end

        context 'with disabled recovery codes' do
          let(:recover_codes_enabled) { false }

          it 'verified is true (but without recovery codes)' do
            expect(json_response['verified']).to be(true)
            expect(json_response['recovery_codes']).to be_nil
          end
        end

        context 'with existing recovery codes' do
          let(:has_recovery_codes) { true }

          it 'verified is true (but without recovery codes)' do
            expect(json_response['verified']).to be(true)
            expect(json_response['recovery_codes']).to be_nil
          end
        end
      end
    end
  end

  describe 'POST /users/two_factor_recovery_codes_generate' do
    let(:recover_codes_enabled) { true }
    let(:current_codes)         { [] }

    before do
      Setting.set('two_factor_authentication_recovery_codes', recover_codes_enabled)
      current_codes
      post '/api/v1/users/two_factor_recovery_codes_generate', params: {}, as: :json
    end

    context 'with disabled recovery codes' do
      let(:recover_codes_enabled) { false }

      it 'does not generate codes' do
        expect(json_response).to be_nil
      end
    end

    context 'without existing recovery codes' do
      it 'does generate codes' do
        expect(json_response.length).to eq(10)
      end
    end

    context 'with existing recovery codes' do
      let(:current_codes) { Auth::TwoFactor::RecoveryCodes.new(agent).generate }

      it 'does not generate codes' do
        expect(json_response).not_to eq(current_codes)
      end
    end
  end

  describe 'GET /users/two_factor_authentication_method_initiate_configuration/:method' do
    let(:two_factor_pref)   { nil }
    let(:method)            { 'authenticator_app' }

    before do
      get "/api/v1/users/two_factor_authentication_method_initiate_configuration/#{method}", as: :json
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

  describe 'GET /users/two_factor_authentication_method_configuration/:method' do
    let(:method) { 'authenticator_app' }

    before do
      get "/api/v1/users/two_factor_authentication_method_configuration/#{method}", as: :json
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
      context 'with no stored two-factor preference' do
        let(:two_factor_pref) { nil }

        it 'returns nothing', :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(json_response['configuration']).to be_empty
        end
      end

      it 'returns configuration', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response['configuration']).to include('secret').and include('code').and include('provisioning_uri')
      end
    end
  end

  describe 'DELETE /users/two_factor_authentication_remove_credentials/:method/:credential_id' do
    it 'fails without needed params' do
      delete '/api/v1/users/two_factor_authentication_remove_credentials/security_keys',
             params: {},
             as:     :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'with needed params' do
      let(:method)        { 'security_keys' }
      let(:credential_id) { 'credential_id' }

      let(:two_factor_pref) do
        create(:user_two_factor_preference, :security_keys, credential_public_key: credential_id, user: agent)
      end

      context 'when removing configuration' do
        let(:params) { { credential_id: } }

        it 'returns ok and updates configuration', :aggregate_failures do
          allow(Service::User::TwoFactor::RemoveMethodCredentials)
            .to receive(:new)
            .and_call_original

          expect_any_instance_of(Service::User::TwoFactor::RemoveMethodCredentials)
            .to receive(:execute)
            .and_call_original

          delete '/api/v1/users/two_factor_authentication_remove_credentials/security_keys',
                 params: params,
                 as:     :json

          expect(response).to have_http_status(:ok)

          expect(Service::User::TwoFactor::RemoveMethodCredentials)
            .to have_received(:new).with(user: agent, method_name: 'security_keys', credential_id:)
        end
      end
    end
  end

  describe 'POST /users/two_factor_default_authentication_method' do
    let(:method) { 'unknown' }
    let(:params) { {} }

    before do
      Setting.set('two_factor_authentication_method_security_keys', two_factor_enabled)
      create(:user_two_factor_preference, :security_keys, user: agent)

      post '/api/v1/users/two_factor_default_authentication_method', params: params, as: :json
    end

    it 'fails without needed params' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'with needed params' do
      let(:params) { { method: method } }
      let(:method) { 'security_keys' }

      it 'returns ok and updates default method', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(agent.reload.preferences.dig(:two_factor_authentication, :default)).to eq(method)
      end
    end
  end
end
