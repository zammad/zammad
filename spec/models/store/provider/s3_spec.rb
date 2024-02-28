# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Store::Provider::S3, authenticated_as: false, integration: true do

  around do |example|
    VCR.configure do |c|
      c.ignore_hosts 's3.eu-central-1.amazonaws.com'
      c.ignore_hosts 's3.eu-central-1.zammad.org'
      c.ignore_hosts ENV['S3_ENDPOINT'] if ENV['S3_ENDPOINT'].present?
    end
    example.run
    described_class.reset
  end

  describe '.client' do
    it 'returns an Aws::S3::Client object' do
      expect(described_class.client).to be_a(Aws::S3::Client)
    end
  end

  describe 'ping?' do
    it 'returns true' do
      expect(described_class.ping?).to be(true)
    end

    context 'when credentials are bad' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:access_key_id] = 'bad'
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'returns false' do
        expect(described_class.ping?).to be(false)
      end
    end

    context 'when bucket is not existing' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:bucket] = config[:bucket] + DateTime.now.strftime('%Q')
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'returns false' do
        expect(described_class.ping?).to be(false)
      end
    end

    context 'when endpoint is not reachable' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:endpoint] = 'https://s3.eu-central-1.zammad.org'
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'returns false' do
        expect(described_class.ping?).to be(false)
      end
    end
  end

  describe '.ping!' do
    context 'when connection succeeds' do
      it 'raises no error' do
        expect { described_class.ping! }.not_to raise_error
      end
    end

    context 'when connection fails' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:endpoint] = 'https://s3.eu-central-1.zammad.org'
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'raises an error' do
        expect { described_class.ping! }.to raise_error(Store::Provider::S3::Error)
      end
    end
  end

  describe '.reset' do
    it 'resets the client and its config', :aggregate_failures do
      described_class.reset
      expect(described_class.instance_variable_get(:@client)).to be_nil
      expect(Store::Provider::S3::Config.instance_variable_get(:@config)).to be_nil
      expect(Aws.config).to be_empty
    end
  end

  describe '.add' do
    let(:data)         { Rails.root.join('spec/fixtures/files/image/large.png').read }
    let(:sha256)       { Digest::SHA256.hexdigest(data) }

    it 'adds a file' do
      expect(described_class.add(data, sha256)).to be_truthy
    end

    context 'when connection fails' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:endpoint] = 'https://s3.eu-central-1.zammad.org'
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'raises an error' do
        expect { described_class.add(data, sha256) }.to raise_error(Store::Provider::S3::Error)
      end
    end

    context 'when file already exists' do
      before do
        described_class.add(data, sha256)
      end

      it 'overrides file' do
        expect { described_class.add(data, sha256) }.not_to raise_error
      end
    end
  end

  describe '.upload' do
    let(:data) { 'data' * 15.megabytes }
    let(:sha256) { Digest::SHA256.hexdigest(data) }

    before do
      config = Store::Provider::S3::Config.send(:settings)
      config[:max_chunk_size] = 10.megabytes
      Store::Provider::S3::Config.instance_variable_set(:@config, config)
    end

    it 'uploads a file' do
      expect(described_class.upload(data, sha256)).to be_truthy
    end

    context 'when max_chunk_size setting is smaller 5MB' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:max_chunk_size] = 2.megabytes
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'raises an error' do
        expect { described_class.upload(data, sha256) }.to raise_error(Store::Provider::S3::Error)
      end
    end
  end

  describe '.delete' do
    let(:data)   { Rails.root.join('spec/fixtures/files/image/large.png').read }
    let(:sha256) { Digest::SHA256.hexdigest(data) }

    it 'deletes a file' do
      described_class.add(data, sha256)
      expect(described_class.delete(sha256)).to be_truthy
    end

    context 'when connection fails' do
      before do
        config = Store::Provider::S3::Config.send(:settings)
        config[:endpoint] = 'https://s3.eu-central-1.zammad.org'
        Store::Provider::S3::Config.instance_variable_set(:@config, config)
      end

      it 'raises an error' do
        expect { described_class.delete(sha256) }.to raise_error(Store::Provider::S3::Error)
      end
    end

    context 'when file does not exist' do
      it 'raises no error' do
        expect { described_class.delete(sha256) }.not_to raise_error
      end
    end
  end

end
