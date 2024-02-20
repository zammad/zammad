# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'requests/channel_admin/base_examples'

RSpec.describe 'WhatsApp channel admin API endpoints', aggregate_failures: true, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  it_behaves_like 'base channel management', factory: :whatsapp_channel, path: :whatsapp

  describe 'POST /api/v1/channels_admin/whatsapp' do
    it 'creates a channel' do
      params = attributes_for(:whatsapp_channel)[:options]

      allow_any_instance_of(Service::Channel::Whatsapp::Create).to receive(:execute)
      allow(Service::Channel::Whatsapp::Create).to receive(:new).and_call_original

      post '/api/v1/channels/admin/whatsapp', params: params

      expect(response).to have_http_status(:ok)
      expect(Service::Channel::Whatsapp::Create).to have_received(:new)
    end
  end

  describe 'PUT /api/v1/channels_admin/whatsapp/ID' do
    let(:channel) { create(:whatsapp_channel) }

    it 'updates a channel' do
      params = attributes_for(:whatsapp_channel)[:options]

      allow_any_instance_of(Service::Channel::Whatsapp::Update).to receive(:execute)
      allow(Service::Channel::Whatsapp::Update).to receive(:new).and_call_original

      put "/api/v1/channels/admin/whatsapp/#{channel.id}", params: params

      expect(response).to have_http_status(:ok)
      expect(Service::Channel::Whatsapp::Update).to have_received(:new)
    end
  end

  describe 'POST /api/v1/channels_admin/whatsapp/preload' do
    it 'returns phone numbers to show in a form' do
      params = { business_id: '123', access_token: 'token' }
      output = {
        'phone_numbers' => [
          { 'name' => 'phone', 'value' => 123 }
        ]
      }

      allow_any_instance_of(Service::Channel::Whatsapp::Preload)
        .to receive(:execute)
        .and_return(output)

      allow(Service::Channel::Whatsapp::Preload).to receive(:new).and_call_original

      post '/api/v1/channels/admin/whatsapp/preload', params: params

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('data' => output)
      expect(Service::Channel::Whatsapp::Preload).to have_received(:new).with(**params)
    end
  end
end
