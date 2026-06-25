# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'autodiscover' # Only load this gem when it is really used.

RSpec.describe 'Exchange integration endpoint', type: :request do
  before { authenticated_as(admin_with_admin_user_permissions) }

  let(:admin_with_admin_user_permissions) do
    create(:user, roles: [role_with_admin_user_permissions])
  end

  let(:role_with_admin_user_permissions) do
    create(:role).tap { |role| role.permission_grant('admin.integration') }
  end

  describe 'job_try' do
    let(:access_token) { 'real_oauth_token_abc123' }

    let(:params) do
      {
        password:   'secret_password',
        endpoint:   'https://exchange.example.com/EWS/Exchange.asmx',
        user:       'user@example.com',
        folders:    ['Contacts'],
        attributes: {},
      }
    end

    before do
      Setting.set('exchange_oauth', { access_token: access_token })

      post '/api/v1/integration/exchange/job_try', params: params, as: :json
      get '/api/v1/integration/exchange/job_try', params: { finished: 'true' }, as: :json
    end

    it 'masks password in the GET response' do
      expect(json_response.dig('payload', 'ews_config', 'password')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end

    it 'masks access_token in the GET response' do
      expect(json_response.dig('payload', 'ews_config', 'access_token')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end

    it 'stores the token in the job payload' do
      expect(ImportJob.last.payload.dig(:ews_config, :access_token)).to eq(access_token)
    end

    it 'does not leak the access_token in the response' do
      expect(response.body).not_to include(access_token)
    end

    it 'does not leak the password in the response' do
      expect(response.body).not_to include(params[:password])
    end

    it 'does not expose raw request params in the payload' do
      expect(json_response['payload']).not_to have_key('params')
    end
  end

  describe 'EWS folder retrieval' do
    # see https://github.com/zammad/zammad/issues/1802
    context 'when no folders found (#1802)' do
      let(:empty_folder_list) { { folders: {} } }

      it 'responds with an error message' do
        allow(Sequencer).to receive(:process).with(any_args).and_return(empty_folder_list)

        post api_v1_integration_exchange_folders_path,
             params: {}, as: :json

        expect(json_response).to include('result' => 'failed').and include('message')
      end
    end
  end

  describe 'autodiscovery' do
    # see https://github.com/zammad/zammad/issues/2065
    context 'when Autodiscover gem raises Errno::EADDRNOTAVAIL (#2065)' do
      let(:client) { instance_double(Autodiscover::Client) }

      it 'rescues and responds with an empty hash (to proceed to manual configuration)' do
        allow(Autodiscover::Client).to receive(:new).with(any_args).and_return(client)
        allow(client).to receive(:autodiscover).and_raise(Errno::EADDRNOTAVAIL)

        post api_v1_integration_exchange_autodiscover_path,
             params: {}, as: :json

        expect(json_response).to eq('result' => 'ok')
      end
    end
  end
end
