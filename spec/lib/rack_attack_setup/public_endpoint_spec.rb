# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RackAttackSetup::PublicEndpoint do
  before do
    allow(Rack::Attack).to receive(:throttle)
  end

  describe '.setup' do
    before do
      allow(described_class).to receive(:setup_ip_throttling)
      allow(described_class).to receive(:setup_field_throttling)
    end

    it 'calls setup_single_throttle for each throttle', :aggregate_failures do
      described_class.setup

      described_class::ENDPOINTS.each do |config|
        expect(described_class).to have_received(:setup_field_throttling).with(config[:url], config[:field])
        expect(described_class).to have_received(:setup_ip_throttling).with(config[:url])
      end
    end
  end

  describe '.setup_ip_throttling', :aggregate_failures do
    let(:request)       { instance_double(Rack::Request, ip: '127.0.0.1', path: request_path, post?: post) }
    let(:throttle_path) { '/some/path/to/throttle' }
    let(:request_path)  { throttle_path }

    context 'when the request is a POST request' do
      let(:post) { true }

      context 'when the request path matches the throttle path' do
        it 'yield block returns IP address' do
          described_class.setup_ip_throttling(throttle_path)

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to eq(request.ip)
          end
        end
      end

      context 'when the request path does not match the throttle path' do
        let(:request_path) { '/some/other/path' }

        it 'yield block returns nil' do
          described_class.setup_ip_throttling(throttle_path)

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to be_nil
          end
        end
      end
    end

    context 'when the request is not a POST request' do
      let(:post) { false }

      it 'yield block returns nil' do
        described_class.setup_ip_throttling(throttle_path)

        expect(Rack::Attack).to have_received(:throttle) do |&block|
          expect(block.call(request)).to be_nil
        end
      end
    end
  end

  describe '.setup_field_throttling', :aggregate_failures do
    let(:request)        { instance_double(Rack::Request, ip: '127.0.0.1', path: request_path, post?: post, params: request_params) }
    let(:throttle_path)  { '/some/path/to/throttle' }
    let(:request_path)   { throttle_path }
    let(:request_params) { { 'field' => 'Some Value', 'other' => '123' } }

    context 'when the request is a POST request' do
      let(:post) { true }

      context 'when the request path matches the throttle path' do
        it 'yield block returns normalized field value' do
          described_class.setup_field_throttling(throttle_path, 'field')

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to eq('somevalue')
          end
        end

        context 'when the target value is missing in the request params' do
          let(:request_params) { {} }

          it 'yield block returns empty string' do
            described_class.setup_field_throttling(throttle_path, 'field')

            expect(Rack::Attack).to have_received(:throttle) do |&block|
              expect(block.call(request)).to eq('')
            end
          end
        end
      end

      context 'when the request path does not match the throttle path' do
        let(:request_path) { '/some/other/path' }

        it 'yield block returns nil' do
          described_class.setup_field_throttling(throttle_path, 'field')

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to be_nil
          end
        end
      end
    end

    context 'when the request is not a POST request' do
      let(:post) { false }

      it 'yield block returns nil' do
        described_class.setup_field_throttling(throttle_path, 'field')

        expect(Rack::Attack).to have_received(:throttle) do |&block|
          expect(block.call(request)).to be_nil
        end
      end
    end
  end
end
