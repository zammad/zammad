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

  let(:hardware_response) do
    {
      id:           1,
      name:         'Laptop-001',
      asset_tag:    'LAP001',
      serial:       'ABC123',
      model:        { id: 1, name: 'MacBook Pro' },
      status_label: { id: 2, name: 'Ready to Deploy' },
      category:     { id: 1, name: 'Laptops' },
      location:     { id: 1, name: 'HQ' },
    }.to_json
  end

  let(:users_response) do
    {
      total: 1,
      rows:  [
        { id: 7, username: 'nicole', email: 'nicole.braun@zammad.org' }
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

    it 'forbids verify for agents', aggregate_failures: true do
      params = {
        api_token: token,
        endpoint:  endpoint,
      }
      authenticated_as(agent)
      post '/api/v1/integration/snipeit/verify', params: params, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('User authorization failed.')
    end

    it 'verifies configuration for admins with a masked token', aggregate_failures: true do
      stub_request(:get, "#{endpoint}api/v1/hardware")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      params = {
        api_token: SensitiveParamsHelper::SENSITIVE_MASK,
        endpoint:  endpoint,
      }
      authenticated_as(admin)
      post '/api/v1/integration/snipeit/verify', params: params, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']).to eq('ok')
      expect(json_response['response']['rows'][0]['id']).to eq(1)
    end

    it 'verifies configuration for admins', aggregate_failures: true do
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

    it 'cleans up endpoint urls on verify', aggregate_failures: true do
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

    it 'queries hardware for agents', aggregate_failures: true do
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

    it 'defaults method to hardware when searching', aggregate_failures: true do
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

    it 'fetches linked assets by id and keeps the raw nested attributes', aggregate_failures: true do
      stub_request(:get, "#{endpoint}api/v1/hardware/1")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_response, headers: { 'Content-Type' => 'application/json' })

      authenticated_as(agent)
      post '/api/v1/integration/snipeit', params: { ids: [1] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['rows'][0]['id']).to eq(1)

      # The legacy sidebar template renders these nested keys directly, so they must not be
      # flattened away on the way out.
      expect(json_response['result']['rows'][0]['model']['name']).to eq('MacBook Pro')
      expect(json_response['result']['rows'][0]['status_label']['name']).to eq('Ready to Deploy')
    end

    it 'suggests assets assigned to the customer using an exact email lookup', aggregate_failures: true do
      users_stub = stub_request(:get, "#{endpoint}api/v1/users?email=nicole.braun%40zammad.org")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: users_response, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "#{endpoint}api/v1/hardware?assigned_to=7&assigned_type=App%5CModels%5CUser")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      authenticated_as(agent)
      post '/api/v1/integration/snipeit', params: { search: 'nicole.braun@zammad.org' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['rows'][0]['id']).to eq(1)
      expect(users_stub).to have_been_requested
    end

    it 'falls back to a regular search when the customer is unknown to Snipe-IT', aggregate_failures: true do
      stub_request(:get, "#{endpoint}api/v1/users?email=unknown%40zammad.org")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: { total: 0, rows: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "#{endpoint}api/v1/hardware?search=unknown%40zammad.org")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

      authenticated_as(agent)
      post '/api/v1/integration/snipeit', params: { search: 'unknown@zammad.org' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['result']['rows'][0]['id']).to eq(1)
    end

    context 'when the integration is disabled' do
      before do
        Setting.set('snipeit_integration', false)
      end

      it 'refuses to query', aggregate_failures: true do
        authenticated_as(agent)
        post '/api/v1/integration/snipeit', params: { search: 'laptop' }, as: :json
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Snipe-IT integration is not enabled')
      end

      it 'refuses to update linked assets' do
        ticket = create(:ticket, group: Group.first)

        authenticated_as(agent)
        post '/api/v1/integration/snipeit_ticket_update', params: { ticket_id: ticket.id, asset_ids: [1] }, as: :json
        expect(response).to have_http_status(:forbidden)
      end

      # Admins have to be able to test a configuration before switching the integration on.
      it 'still allows admins to verify the configuration', aggregate_failures: true do
        stub_request(:get, "#{endpoint}api/v1/hardware")
          .with(headers: { 'Authorization' => "Bearer #{token}" })
          .to_return(status: 200, body: hardware_list_response, headers: { 'Content-Type' => 'application/json' })

        authenticated_as(admin)
        post '/api/v1/integration/snipeit/verify', params: { api_token: token, endpoint: endpoint }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response['result']).to eq('ok')
      end
    end

    it 'updates linked assets for agents with change access', aggregate_failures: true do
      ticket = create(:ticket, group: Group.first)

      authenticated_as(agent)
      post '/api/v1/integration/snipeit_ticket_update', params: { ticket_id: ticket.id, asset_ids: [1, '1', 2] }, as: :json
      expect(response).to have_http_status(:ok)
      expect(ticket.reload.preferences).to include(snipeit: { asset_ids: [1, 2] })
    end

    it 'forbids updating linked assets for agents with read-only access', aggregate_failures: true do
      group = create(:group)
      ticket = create(:ticket, group: group)
      read_only_agent = create(:agent)
      read_only_agent.user_groups.create!(group: group, access: 'read')

      authenticated_as(read_only_agent)
      post '/api/v1/integration/snipeit_ticket_update', params: { ticket_id: ticket.id, asset_ids: [1] }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(ticket.reload.preferences[:snipeit]).to be_blank
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
