# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SMS channel API endpoints', :aggregate_failures, authenticated_as: :admin, type: :request do
  let(:admin)   { create(:admin) }
  let(:channel) { create(:sms_message_bird_channel) }
  let(:token)   { channel.options['token'] }

  describe 'GET /api/v1/channels_sms/:id' do
    it 'masks the token' do
      get "/api/v1/channels_sms/#{channel.id}", as: :json

      expect(json_response.dig('options', 'token')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end
  end

  describe 'POST /api/v1/channels_sms_enable' do
    # inactive on purpose, otherwise the state expectation below could not fail
    let(:channel) { create(:sms_message_bird_channel, active: false) }

    it 'does not return the channel' do
      post '/api/v1/channels_sms_enable', params: { id: channel.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq({})
      expect(channel.reload).to be_active
    end
  end

  describe 'POST /api/v1/channels_sms_disable' do
    it 'does not return the channel' do
      post '/api/v1/channels_sms_disable', params: { id: channel.id }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to eq({})
      expect(channel.reload).not_to be_active
    end
  end

  describe 'PUT /api/v1/channels_sms/:id' do
    # the provider dialog posts back the masked token it received via assets
    let(:params) do
      {
        area:    'Sms::Account',
        options: channel.options.merge('token' => SensitiveParamsHelper::SENSITIVE_MASK, 'sender' => '+491110000000'),
      }
    end

    it 'restores the stored token instead of persisting the mask' do
      put "/api/v1/channels_sms/#{channel.id}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(channel.reload.options['token']).to eq(token)
    end

    it 'stores the changed options' do
      put "/api/v1/channels_sms/#{channel.id}", params: params, as: :json

      expect(channel.reload.options['sender']).to eq('+491110000000')
    end

    it 'masks the token in the response' do
      put "/api/v1/channels_sms/#{channel.id}", params: params, as: :json

      expect(json_response.dig('options', 'token')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end
  end

  describe 'POST /api/v1/channels_sms/test' do
    let(:driver) { instance_double(Channel::Driver::Sms::MessageBird, deliver: true) }

    before do
      allow(Channel::Driver::Sms::MessageBird).to receive(:new).and_return(driver)
    end

    it 'uses the given token' do
      post '/api/v1/channels_sms/test', params: {
        recipient: '+491110000000',
        message:   'test',
        options:   channel.options.merge('token' => 'new-token'),
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(driver).to have_received(:deliver) { |options, _attr| expect(options['token']).to eq('new-token') }
    end

    # the drivers put the token into the gateway URL and echo that URL in their error
    # messages, which this endpoint renders back to the client - so it must never restore
    # the stored token, even though that means an existing channel cannot be tested
    # without entering the token again
    it 'does not restore the stored token' do
      post '/api/v1/channels_sms/test', params: {
        recipient: '+491110000000',
        message:   'test',
        options:   channel.options.merge('token' => SensitiveParamsHelper::SENSITIVE_MASK),
      }, as: :json

      expect(driver).to have_received(:deliver) { |options, _attr| expect(options['token']).to eq(SensitiveParamsHelper::SENSITIVE_MASK) }
    end
  end
end
