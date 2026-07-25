# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Snipeit', type: :request do
  let!(:admin) do
    create(:admin, groups: Group.all)
  end
  let!(:agent) do
    create(:agent, groups: Group.all)
  end
  let!(:token) do
    'some_token'
  end
  let!(:endpoint) do
    'https://snipeit.example.com/'
  end

  let(:hardware_list_response) do
    {
      total: 1,
      rows:  [
        {
          id:           1,
          name:         'Laptop-001',
          asset_tag:    'LAP001',
          serial:       'ABC123',
          model:        { id: 1, name: 'MacBook Pro' },
          status_label: { id: 2, name: 'Ready to Deploy' },
          category:     { id: 1, name: 'Laptops' },
          location:     { id: 1, name: 'HQ' },
        }
      ]
    }.to_json
  end

  before do
    Setting.set('snipeit_integration', true)
    Setting.set('snipeit_config', {
                  api_token:  token,
                  endpoint:   endpoint,
                  verify_ssl: false,
                })
  end

  describe 'request handling' do

    it 'forbids verify for agents' do
      params = {
        api_token: token,
        endpoint:  endpoint,
      }
      authenticated_as(agent)
      post '/api/v1/integration/snipeit/verify', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'verifies configuration for admins' do
      stub_request(:get, "#{endpoint}api/v1/hardware")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      params = {
        api_token: token,
        endpoint:  endpoint,
      }
      authenticated_as(admin)
      post '/api/v1/integration/snipeit/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']['rows'][0]['id']).to eq(1)
      expect(json_response['response']['rows'][0]['link']).to eq("#{endpoint}hardware/1")
    end

    it 'cleans up endpoint urls on verify' do
      stub_request(:get, "#{endpoint}api/v1/hardware")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      params = {
        api_token: token,
        endpoint:  " #{endpoint}/",
      }
      authenticated_as(admin)
      post '/api/v1/integration/snipeit/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']).to eq('ok')
    end

    it 'queries hardware for agents' do
      stub_request(:get, "#{endpoint}api/v1/hardware?search=laptop")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      params = {
        method: 'hardware',
        search: 'laptop',
      }
      authenticated_as(agent)
      post '/api/v1/integration/snipeit', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['rows'][0]['name']).to eq('Laptop-001')
      expect(json_response['result']['rows'][0]['link']).to eq("#{endpoint}hardware/1")
    end

    it 'defaults method to hardware when searching' do
      stub_request(:get, "#{endpoint}api/v1/hardware?search=laptop")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      params = {
        search: 'laptop',
      }
      authenticated_as(agent)
      post '/api/v1/integration/snipeit', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['rows'][0]['id']).to eq(1)
    end
  end

  describe 'SSL verification' do
    describe '.verify' do
      def request(verify: false)
        stub_request(:get, "#{endpoint}api/v1/hardware")
          .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

        params = {
          api_token:  token,
          endpoint:   endpoint,
          verify_ssl: verify
        }
        authenticated_as(admin)
        post '/api/v1/integration/snipeit/verify', params: params, as: :json
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
