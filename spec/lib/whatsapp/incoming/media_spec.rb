# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
      allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:media).and_return(internal_response1)
      allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:download).and_return(internal_response2)
    end

    context 'with successful response' do
      let(:url)       { Faker::Internet.unique.url }
      let(:mime_type) { 'image/jpeg' }

      let(:internal_response1) do
        Struct.new(:data, :error).new(Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum), nil)
      end

      let(:internal_response2) do
        Struct.new(:data, :error).new(Struct.new(:success).new(true), nil)
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

    context 'with unsuccessful response (1)' do
      let(:internal_response1) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      let(:internal_response2) do
        Struct.new(:data, :error).new(Struct.new(:success).new(true), nil)
      end

      it 'raises an error' do
        expect { instance.download(media_id:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end

    context 'with unsuccessful response (2)' do
      let(:url)       { Faker::Internet.unique.url }
      let(:mime_type) { 'image/jpeg' }

      let(:internal_response1) do
        Struct.new(:data, :error).new(Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum), nil)
      end

      let(:internal_response2) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      it 'raises an error' do
        expect { instance.download(media_id:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end

    context 'with an invalid checksum' do
      let(:url)       { Faker::Internet.unique.url }
      let(:mime_type) { 'image/jpeg' }

      let(:internal_response1) do
        Struct.new(:data, :error).new(Struct.new(:url, :mime_type, :sha256).new(url, mime_type, Faker::Crypto.unique.sha256), nil)
      end

      let(:internal_response2) do
        Struct.new(:data, :error).new(Struct.new(:success).new(true), nil)
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
