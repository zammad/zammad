# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Whatsapp::Webhook::Payload::Error', :aggregate_failures, current_user_id: 1 do
  let(:channel) { create(:whatsapp_channel) }
  let(:wa_id)   { Faker::PhoneNumber.unique.cell_phone_in_e164.delete('+') }
  let(:errors)  { {} }
  let(:json) do
    {
      object: 'whatsapp_business_account',
      entry:  [
        {
          id:      '222259550976437',
          changes: [
            {
              value: {
                messaging_product: 'whatsapp',
                metadata:          {
                  display_phone_number: channel.options[:phone_number],
                  phone_number_id:      channel.options[:phone_number_id]
                },
                contacts:          [
                  {
                    profile: {
                      name: Faker::Name.unique.name
                    },
                    wa_id:   wa_id
                  }
                ],
                messages:          [
                  {
                    from:      wa_id,
                    id:        'wamid.NDkxNTE1NTU1NTU5ODNBNTU3NkYyQTJCM0FGMUE1RjZECg==',
                    timestamp: '1733484661',
                    errors:    [
                      error
                    ],
                    type:      'any'
                  }
                ]
              },
              field: 'messages'
            }
          ]
        }
      ]
    }.to_json
  end
  let(:uuid) { channel.options[:callback_url_uuid] }
  let(:signature) do
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), channel.options[:app_secret], json)
  end

  context 'when error is initialized by sender' do

    let(:error) do
      {
        code:       131_051,
        title:      'Message type unknown',
        message:    'Message type unknown',
        error_data: {
          details: 'Message type is currently not supported.'
        }
      }
    end
    let(:message) { instance_double(Whatsapp::Outgoing::Message::Text) }

    before do
      allow(Whatsapp::Outgoing::Message::Text)
        .to receive(:new)
        .and_return(message)
      allow(message)
        .to receive(:deliver)
        .with(body: "Apologies, we're unable to process this kind of message due to restrictions within WhatsApp Business.")
        .and_return(true)
      allow(Rails.logger).to receive(:error)
      begin
        Whatsapp::Webhook::Payload.new(json: json, signature: signature, uuid: uuid).process
      rescue Whatsapp::Webhook::Payload::ProcessableError
        # noop
      end
    end

    it 'does log error' do
      expect(Rails.logger).to have_received(:error).once
    end

    it 'does inform sender' do
      expect(message).to have_received(:deliver).once
    end

    it 'does not update channel status' do
      expect(channel.reload.status_out).to be_nil
      expect(channel.reload.last_log_out).to be_nil
    end
  end

  context 'when error is recoverable' do
    let(:error) do
      {
        code:       131_026,
        title:      'Message undeliverable',
        message:    'Message undeliverable',
        error_data: {
          details: 'Message could not be delivered.'
        }
      }
    end

    before do
      allow(Rails.logger).to receive(:error)
      begin
        Whatsapp::Webhook::Payload.new(json: json, signature: signature, uuid: uuid).process
      rescue Whatsapp::Webhook::Payload::ProcessableError
        # noop
      end
    end

    it 'does log error' do
      expect(Rails.logger).to have_received(:error).once
    end

    it 'does not update channel status' do
      expect(channel.reload.status_out).to be_nil
      expect(channel.reload.last_log_out).to be_nil
    end
  end

  context 'when error is not recoverable' do
    let(:error) do
      {
        code:       131_056,
        title:      'Pair rate limit hit',
        message:    'Pair rate limit hit',
        error_data: {
          details: 'Too many messages sent to this user.'
        }
      }
    end

    before do
      allow(Rails.logger).to receive(:error)
      begin
        Whatsapp::Webhook::Payload.new(json: json, signature: signature, uuid: uuid).process
      rescue Whatsapp::Webhook::Payload::ProcessableError
        # noop
      end
    end

    it 'does log error' do
      expect(Rails.logger).to have_received(:error).once
    end

    it 'does update channel status' do
      expect(channel.reload.status_out).to eq('error')
      expect(channel.reload.last_log_out).to eq('Pair rate limit hit (131056)')
    end
  end
end
