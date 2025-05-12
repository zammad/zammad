# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Incoming::Media do
  let(:instance)       { described_class.new(**params) }
  let(:media_content)  { SecureRandom.uuid }
  let(:media_file)     { Tempfile.create('social.jpg').tap { |f| File.write(f, media_content) } }
  let(:valid_checksum) { Digest::SHA2.new(256).hexdigest(media_content) }

  let(:params) do
    {
      access_token: Faker::Omniauth.unique.facebook[:credentials][:token],
    }
  end

  describe '.download' do
    let(:media_id) { Faker::Number.unique.number(digits: 15) }

    before do
      allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:get).and_return(internal_response1)
      allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:download).and_return(internal_response2)
    end

    context 'with successful response' do
      let(:url)       { Faker::Internet.unique.url }
      let(:mime_type) { 'image/jpeg' }

      let(:internal_response1) do
        Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum)
      end

      let(:internal_response2) do
        Struct.new(:success).new(true)
      end

      before do
        allow_any_instance_of(described_class).to receive(:with_tmpfile).and_yield(media_file)
      end

      after do
        File.unlink(media_file)
      end

      it 'returns downloaded media in base64 encoding' do
        expect(instance.download(media_id:)).to eq([File.read(media_file), mime_type])
      end
    end

    context 'with unsuccessful response' do
      context 'when retreiving metadata fails' do
        before do
          exception = WhatsappSdk::Api::Responses::HttpResponseError.new(
            body:        Struct.new(:error).new({ 'message' => 'error message' }),
            http_status: 500,
          )
          allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:get).and_raise(exception)
        end

        let(:internal_response1) { nil }
        let(:internal_response2) { nil }

        it 'raises an error' do
          expect { instance.download(media_id:) }.to raise_error(Whatsapp::Client::CloudAPIError)
        end
      end

      context 'when retreiving media fails' do
        before do
          exception = WhatsappSdk::Api::Responses::HttpResponseError.new(
            body:        Struct.new(:error).new({ 'message' => 'error message' }),
            http_status: 500,
          )
          allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:download).and_raise(exception)
        end

        let(:url)       { Faker::Internet.unique.url }
        let(:mime_type) { 'image/jpeg' }

        let(:internal_response1) do
          Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum)
        end
        let(:internal_response2) { nil }

        it 'raises an error' do
          expect { instance.download(media_id:) }.to raise_error(Whatsapp::Client::CloudAPIError)
        end
      end
    end

    context 'with an invalid checksum' do
      let(:url)       { Faker::Internet.unique.url }
      let(:mime_type) { 'image/jpeg' }

      let(:internal_response1) do
        Struct.new(:url, :mime_type, :sha256).new(url, mime_type, Faker::Crypto.unique.sha256)
      end

      let(:internal_response2) do
        Struct.new(:success).new(true)
      end

      before do
        allow_any_instance_of(described_class).to receive(:with_tmpfile).and_yield(media_file)
      end

      after do
        File.unlink(media_file)
      end

      it 'raises an error' do
        expect { instance.download(media_id:) }.to raise_error(Whatsapp::Incoming::Media::InvalidChecksumError, 'Integrity verification of the downloaded WhatsApp media failed.')
      end
    end
  end
end
