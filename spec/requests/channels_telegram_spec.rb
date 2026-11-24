# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Telegram channel API endpoints', :aggregate_failures, authenticated_as: :admin, type: :request do
  include_context 'with Telegram bot info'

  let(:admin)     { create(:admin) }
  let(:channel)   { create(:telegram_channel) }
  let(:api_token) { channel.options['api_token'] }
  let(:bot_id)    { channel.options.dig('bot', 'id') }

  describe 'GET /api/v1/channels_telegram' do
    it 'masks the api token' do
      channel && get('/api/v1/channels_telegram', as: :json)

      expect(json_response.dig('assets', 'Channel', channel.id.to_s, 'options', 'api_token'))
        .to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end
  end

  describe 'POST /api/v1/channels_telegram' do
    let(:new_token) { '123456789:new-api-token' }

    before do
      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'zammad.example.com')

      stub_telegram_get_me(new_token, id: 123_456_789, username: 'newbot', first_name: 'Bot')
      stub_request(:post, "https://api.telegram.org/bot#{new_token}/setWebhook")
        .to_return(status: 200, body: { ok: true, result: true }.to_json, headers: {})
    end

    it 'masks the api token in the response' do
      post '/api/v1/channels_telegram', params: { api_token: new_token, group_id: Group.first.id, welcome: 'Hi!', goodbye: 'Bye!' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('options', 'api_token')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end

    it 'returns a null last name for a new bot' do
      post '/api/v1/channels_telegram', params: { api_token: new_token, group_id: Group.first.id }, as: :json

      expect(json_response.dig('options', 'bot')).to include('last_name' => nil)
    end

    it 'stores the given api token' do
      post '/api/v1/channels_telegram', params: { api_token: new_token, group_id: Group.first.id, welcome: 'Hi!', goodbye: 'Bye!' }, as: :json

      expect(Channel.last.options['api_token']).to eq(new_token)
    end
  end

  describe 'PUT /api/v1/channels_telegram/:id' do
    # the bot dialog posts back the masked api token it received via assets
    let(:params) do
      {
        api_token: SensitiveParamsHelper::SENSITIVE_MASK,
        group_id:  Group.first.id,
        welcome:   'Hi!',
        goodbye:   'Bye!',
      }
    end

    before do
      Setting.set('http_type', 'https')
      Setting.set('fqdn', 'zammad.example.com')

      stub_telegram_get_me(api_token, id: bot_id, username: 'bot', first_name: 'Bot')
      stub_request(:post, "https://api.telegram.org/bot#{api_token}/setWebhook")
        .to_return(status: 200, body: { ok: true, result: true }.to_json, headers: {})
    end

    it 'restores the stored api token instead of sending the mask to Telegram' do
      put "/api/v1/channels_telegram/#{channel.id}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(channel.reload.options['api_token']).to eq(api_token)
    end

    it 'preserves the stored last name for the same bot' do
      last_name = channel.options.dig('bot', 'last_name')
      put "/api/v1/channels_telegram/#{channel.id}", params: params, as: :json

      expect(json_response.dig('options', 'bot')).to include('last_name' => last_name)
      expect(channel.reload.options.dig('bot', 'last_name')).to eq(last_name)
    end

    it 'clears the previous last name when switching bots' do
      stub_telegram_get_me('replacement-token', id: bot_id + 1, username: 'replacementbot', first_name: 'Replacement')
      stub_request(:post, 'https://api.telegram.org/botreplacement-token/setWebhook')
        .to_return_json(body: { ok: true, result: true })
      put "/api/v1/channels_telegram/#{channel.id}", params: params.merge(api_token: 'replacement-token'), as: :json

      expect(json_response.dig('options', 'bot')).to include('id' => bot_id + 1, 'last_name' => nil)
    end

    it 'stores the changed options' do
      put "/api/v1/channels_telegram/#{channel.id}", params: params, as: :json

      expect(channel.reload.options).to include('welcome' => 'Hi!', 'goodbye' => 'Bye!')
    end

    it 'masks the api token in the response' do
      put "/api/v1/channels_telegram/#{channel.id}", params: params, as: :json

      expect(json_response.dig('options', 'api_token')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
    end
  end
end
