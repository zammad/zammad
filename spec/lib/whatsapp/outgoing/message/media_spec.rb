# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Outgoing::Message::Media do
  let(:instance) { described_class.new(**params) }

  let(:params) do
    {
      access_token:     Faker::Omniauth.unique.facebook[:credentials][:token],
      phone_number_id:  Faker::Number.unique.number(digits: 15),
      recipient_number: Faker::PhoneNumber.unique.cell_phone_in_e164,
    }
  end

  describe '.supported_media_type?' do
    supported_mime_types = {
      audio:    ['audio/aac', 'audio/mp4', 'audio/mpeg', 'audio/amr', 'audio/ogg'],
      document: ['text/plain', 'application/pdf', 'application/vnd.ms-powerpoint', 'application/msword', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
      image:    ['image/jpeg', 'image/png'],
      sticker:  ['image/webp'],
      video:    ['video/mp4', 'video/3gp'],
    }

    supported_mime_types.each_value do |mime_types|
      mime_types.each do |mime_type|
        it "returns true for supported media type (#{mime_type})" do
          expect(instance.supported_media_type?(mime_type:)).to be(true)
        end
      end
    end

    it 'returns false for unsupported media type' do
      expect(instance.supported_media_type?(mime_type: 'application/octet-stream')).to be(false)
    end
  end

  shared_examples 'delivering media message type and handling response errors' do |mime_type:, mock_method:|
    let(:store)              { create(:store, preferences: { 'Mime-Type' => mime_type }) }
    let(:media_id)           { Faker::Number.unique.number(digits: 15) }
    let(:message_id)         { "wamid.#{Faker::Crypto.unique.sha1}==" }
    let(:internal_response1) { Struct.new(:data, :error).new(Struct.new(:id).new(media_id), nil) }
    let(:internal_response2) { Struct.new(:data, :error).new(Struct.new(:messages).new([Struct.new(:id).new(message_id)]), nil) }

    before do
      allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:upload).and_return(internal_response1)
      allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(mock_method).and_return(internal_response2)
    end

    context 'with successful response' do
      let(:response) { { id: message_id } }

      it 'returns sent message id' do
        expect(instance.deliver(store:)).to eq(response)
      end

      context 'with optional caption' do
        it 'returns sent message id' do
          expect(instance.deliver(store:, caption: 'foobar')).to eq(response)
        end
      end
    end

    context 'with unsuccessful response (1)' do
      let(:internal_response1) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      it 'raises an error' do
        expect { instance.deliver(store:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end

    context 'with unsuccessful response (2)' do
      let(:internal_response2) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      it 'raises an error' do
        expect { instance.deliver(store:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end
  end

  describe '.deliver' do
    context 'with audio media type' do
      it_behaves_like 'delivering media message type and handling response errors', mime_type: 'audio/ogg', mock_method: :send_audio
    end

    context 'with document media type' do
      it_behaves_like 'delivering media message type and handling response errors', mime_type: 'application/pdf', mock_method: :send_document
    end

    context 'with image media type' do
      it_behaves_like 'delivering media message type and handling response errors', mime_type: 'image/png', mock_method: :send_image
    end

    context 'with sticker media type' do
      it_behaves_like 'delivering media message type and handling response errors', mime_type: 'image/webp', mock_method: :send_sticker
    end

    context 'with video media type' do
      it_behaves_like 'delivering media message type and handling response errors', mime_type: 'video/mp4', mock_method: :send_video
    end
  end
end
