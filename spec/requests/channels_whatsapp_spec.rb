# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'WhatsApp channel webhook endpoints', aggregate_failures: true, type: :request do

  let(:channel) { create(:whatsapp_channel) }

  describe 'GET /api/v1/channels_whatsapp_webhook/:callback_url_uuid' do
    let(:hub_mode) { 'subscribe' }

    let(:params) do
      {
        'hub.mode':         hub_mode,
        'hub.challenge':    '123',
        'hub.verify_token': channel.options[:verify_token],
      }
    end

    context 'when no channel exists' do
      it 'returns 422' do
        get "/api/v1/channels_whatsapp_webhook/1337#{Faker::Number.unique.number(digits: 15)}", params: params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when everything is valid' do
      it 'returns the challenge' do
        get "/api/v1/channels_whatsapp_webhook/#{channel.options[:callback_url_uuid]}", params: params

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('123')
      end
    end
  end

  describe 'POST /api/v1/channels_whatsapp_webhook' do
    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name
      }
    end

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [{
          id:      '222259550976437',
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              metadata:          {
                display_phone_number: '15551340563',
                phone_number_id:      channel.options[:phone_number_id]
              },
              contacts:          [{
                profile: {
                  name: from[:name]
                },
                wa_id:   from[:phone]
              }],
              messages:          [{
                from:      from[:phone],
                id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
                timestamp: '1707921703',
                text:      {
                  body: 'Hello, world!'
                },
                type:      'text'
              }]
            },
            field: 'messages'
          }]
        }]
      }.to_json
    end

    let(:signature) do
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), channel.options[:app_secret], json)
    end

    context 'when payload validation fails' do
      let(:signature) { 'invalid' }

      it 'returns 422' do
        post "/api/v1/channels_whatsapp_webhook/#{channel.options[:callback_url_uuid]}", headers: { 'X-Hub-Signature-256': "sha256=#{signature}" }, params: json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when everything is valid' do
      it 'returns 200' do
        post "/api/v1/channels_whatsapp_webhook/#{channel.options[:callback_url_uuid]}", headers: { 'X-Hub-Signature-256': "sha256=#{signature}" }, params: json

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
