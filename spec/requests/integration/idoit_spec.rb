# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Idoit', type: :request do
  let!(:admin) do
    create(:admin, groups: Group.all)
  end
  let!(:agent) do
    create(:agent, groups: Group.all)
  end
  let!(:customer) do
    create(:customer)
  end
  let!(:token) do
    'some_token'
  end
  let!(:endpoint) do
    'https://idoit.example.com/i-doit/'
  end

  def read_message(file)
    Rails.root.join('test', 'data', 'idoit', "#{file}.json").read
  end

  before do
    Setting.set('idoit_integration', true)
    Setting.set('idoit_config', {
                  api_token: token,
                  endpoint:  endpoint,
                  client_id: '',
                })
  end

  describe 'request handling' do

    it 'does unclear urls' do

      params = {
        api_token: token,
        endpoint:  endpoint,
        client_id: '',
      }
      authenticated_as(agent)
      post '/api/v1/integration/idoit/verify', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['error']).to eq('User authorization failed.')

      stub_request(:post, "#{endpoint}src/jsonrpc.php")
        .with(body: "{\"method\":\"cmdb.object_types\",\"params\":{\"apikey\":\"#{token}\"},\"version\":\"2.0\",\"id\":42}")
        .to_return(status: 200, body: read_message('object_types_response'), headers: {})

      params = {
        api_token: token,
        endpoint:  endpoint,
        client_id: '',
      }
      authenticated_as(admin)
      post '/api/v1/integration/idoit/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to be_truthy
      expect(json_response['response']['jsonrpc']).to eq('2.0')
      expect(json_response['response']['result']).to be_truthy

      params = {
        api_token: token,
        endpoint:  " #{endpoint}/",
        client_id: '',
      }
      post '/api/v1/integration/idoit/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to be_truthy
      expect(json_response['response']['jsonrpc']).to eq('2.0')
      expect(json_response['response']['result']).to be_truthy

    end

    it 'does list all object types' do

      stub_request(:post, "#{endpoint}src/jsonrpc.php")
        .with(body: "{\"method\":\"cmdb.object_types\",\"params\":{\"apikey\":\"#{token}\"},\"version\":\"2.0\",\"id\":42}")
        .to_return(status: 200, body: read_message('object_types_response'), headers: {})

      params = {
        method: 'cmdb.object_types',
      }
      authenticated_as(agent)
      post '/api/v1/integration/idoit', params: params, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to be_truthy
      expect(json_response['response']['jsonrpc']).to eq('2.0')
      expect(json_response['response']['result']).to be_truthy
      expect(json_response['response']['result'][0]['id']).to eq('1')
      expect(json_response['response']['result'][0]['title']).to eq('System service')

      params = {
        method: 'cmdb.object_types',
      }
      authenticated_as(admin)
      post '/api/v1/integration/idoit', params: params, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to be_truthy
      expect(json_response['response']['jsonrpc']).to eq('2.0')
      expect(json_response['response']['result']).to be_truthy
      expect(json_response['response']['result'][0]['id']).to eq('1')
      expect(json_response['response']['result'][0]['title']).to eq('System service')

    end

    it 'does query objects' do

      stub_request(:post, "#{endpoint}src/jsonrpc.php")
        .with(body: "{\"method\":\"cmdb.objects\",\"params\":{\"apikey\":\"#{token}\",\"filter\":{\"ids\":[\"33\"]}},\"version\":\"2.0\",\"id\":42}")
        .to_return(status: 200, body: read_message('object_types_filter_response'), headers: {})

      params = {
        method: 'cmdb.objects',
        filter: {
          ids: ['33']
        },
      }
      authenticated_as(agent)
      post '/api/v1/integration/idoit', params: params, as: :json
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response).not_to be_blank
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']).to be_truthy
      expect(json_response['response']['jsonrpc']).to eq('2.0')
      expect(json_response['response']['result']).to be_truthy
      expect(json_response['response']['result'][0]['id']).to eq('26')
      expect(json_response['response']['result'][0]['title']).to eq('demo.example.com')
      expect(json_response['response']['result'][0]['type_title']).to eq('Virtual server')
      expect(json_response['response']['result'][0]['cmdb_status_title']).to eq('in operation')

    end
  end

  describe 'SSL verification' do
    describe '.verify' do
      def request(verify: false)
        params = {
          api_token:  token,
          endpoint:   endpoint,
          client_id:  '',
          verify_ssl: verify
        }
        authenticated_as(admin)
        post '/api/v1/integration/idoit/verify', params: params, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'does verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request(verify: true)
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: true)).once
      end

      it 'does not verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: false)).once
      end
    end

    describe '.query' do
      def request(verify: false)
        Setting.set('idoit_config', Setting.get('idoit_config').merge(verify_ssl: verify))

        stub_request(:post, "#{endpoint}src/jsonrpc.php")
          .with(body: "{\"method\":\"cmdb.object_types\",\"params\":{\"apikey\":\"#{token}\"},\"version\":\"2.0\",\"id\":42}")
          .to_return(status: 200, body: read_message('object_types_response'), headers: {})

        params = {
          method: 'cmdb.objects',
          filter: {
            ids: ['33']
          },
        }
        authenticated_as(agent)
        post '/api/v1/integration/idoit', params: params, as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'does verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request(verify: true)
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: true)).once
      end

      it 'does not verify SSL' do
        allow(UserAgent).to receive(:get_http)
        request
        expect(UserAgent).to have_received(:get_http).with(URI::HTTPS, hash_including(verify_ssl: false)).once
      end
    end
  end
end
