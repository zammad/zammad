# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'requests/channel_admin/base_examples'

RSpec.describe 'WhatsApp channel admin API endpoints', aggregate_failures: true, authenticated_as: :user, type: :request do
  let(:user) { create(:admin) }

  it_behaves_like 'base channel management', factory: :whatsapp_channel, path: :whatsapp

  describe 'POST /api/v1/channels_admin/whatsapp' do
    it 'creates a channel' do
      params = attributes_for(:whatsapp_channel)[:options]

      allow_any_instance_of(Service::Channel::Whatsapp::Create)
        .to receive(:execute)
        .and_return(create(:whatsapp_channel))
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

      allow_any_instance_of(Service::Channel::Whatsapp::Update)
        .to receive(:execute)
        .and_return(channel)
      allow(Service::Channel::Whatsapp::Update).to receive(:new).and_call_original

      put "/api/v1/channels/admin/whatsapp/#{channel.id}", params: params

      expect(response).to have_http_status(:ok)
      expect(Service::Channel::Whatsapp::Update).to have_received(:new)
      expect(json_response).to include(
        'options' => include(
          'access_token' => SensitiveParamsHelper::SENSITIVE_MASK
        )
      )
    end

    context 'with masked sensitive params' do
      it 'restores original sensitive values from the channel' do
        original_access_token = channel.options['access_token']
        original_app_secret   = channel.options['app_secret']

        allow_any_instance_of(Service::Channel::Whatsapp::Update)
          .to receive(:execute)
          .and_return(channel)
        allow(Service::Channel::Whatsapp::Update).to receive(:new).and_call_original

        params = attributes_for(:whatsapp_channel)[:options].merge(
          access_token: SensitiveParamsHelper::SENSITIVE_MASK,
          app_secret:   SensitiveParamsHelper::SENSITIVE_MASK,
        )

        put "/api/v1/channels/admin/whatsapp/#{channel.id}", params: params

        expect(response).to have_http_status(:ok)
        expect(Service::Channel::Whatsapp::Update).to have_received(:new).with(
          params:     include(
            'access_token' => original_access_token,
            'app_secret'   => original_app_secret,
          ),
          channel_id: channel.id.to_s,
        )
      end
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

    context 'with masked access_token and channel_id' do
      let(:channel) { create(:whatsapp_channel) }
      let(:params)  { { business_id: channel.options['business_id'], access_token: SensitiveParamsHelper::SENSITIVE_MASK, channel_id: channel.id } }
      let(:output) do
        {
          'phone_numbers' => [
            { 'name' => 'phone', 'value' => 123 }
          ]
        }
      end

      it 'restores the real access_token from the channel' do
        allow_any_instance_of(Service::Channel::Whatsapp::Preload)
          .to receive(:execute)
          .and_return(output)

        allow(Service::Channel::Whatsapp::Preload).to receive(:new).and_call_original

        post '/api/v1/channels/admin/whatsapp/preload', params: params

        expect(response).to have_http_status(:ok)
        expect(Service::Channel::Whatsapp::Preload).to have_received(:new).with(business_id: channel.options['business_id'].to_s, access_token: channel.options['access_token'])
      end
    end
  end
end
