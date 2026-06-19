# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RackAttackSetup::FormEndpoint do
  describe '.setup_single_throttle', :aggregate_failures do
    let(:name)        { 'test throttle' }
    let(:setting)     { 'test_throttle_limit' }
    let(:default)     { 10 }
    let(:period)      { 1.hour }
    let(:return_proc) { proc(&:ip) }

    before do
      allow(Rack::Attack).to receive(:throttle)
    end

    it 'sets up a throttle with the correct name and period' do
      described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

      expect(Rack::Attack)
        .to have_received(:throttle)
        .with(name, limit: anything, period: period.to_i)
    end

    describe 'the limit proc' do
      context 'when the setting is not set' do
        it 'uses the default limit' do
          described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

          expect(Rack::Attack).to have_received(:throttle) do |_, kwargs|
            expect(kwargs[:limit].call).to eq(default)
          end
        end
      end

      context 'when the setting is set' do
        let(:setting_value) { 5 }

        before do
          allow(Setting).to receive(:get).with(setting).and_return(setting_value)
        end

        it 'uses the limit from the setting' do
          described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

          expect(Rack::Attack).to have_received(:throttle) do |_, kwargs|
            expect(kwargs[:limit].call).to eq(setting_value)
          end
        end
      end
    end

    describe 'the return proc' do
      let(:request)     { instance_double(Rack::Request, ip: '127.0.0.1', path:) }
      let(:path)        { described_class::API_V1_FORM_SUBMIT_PATH }
      let(:return_proc) { proc { described_class::API_V1_FORM_SUBMIT_PATH } }

      context 'when the return proc returns a constant' do
        it 'returns the constant value' do
          described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to eq(described_class::API_V1_FORM_SUBMIT_PATH)
          end
        end
      end
    end

    describe 'the throttle block' do
      let(:request) { instance_double(Rack::Request, ip: '127.0.0.1', path:) }

      context 'when the request path does not match the throttle path' do
        let(:path) { '/some/other/path' }

        it 'yield block returns nil' do
          described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to be_nil
          end
        end
      end

      context 'when the request path matches the throttle path' do
        let(:path) { described_class::API_V1_FORM_SUBMIT_PATH }

        it 'yield block returns the value of the specified attribute' do
          described_class.setup_single_throttle(name:, setting:, default:, period:, return_proc:)

          expect(Rack::Attack).to have_received(:throttle) do |&block|
            expect(block.call(request)).to eq(request.ip)
          end
        end
      end
    end
  end

  describe '.setup' do
    before do
      allow(described_class).to receive(:setup_single_throttle)
    end

    it 'calls setup_single_throttle for each throttle configuration' do
      described_class.setup

      described_class::THROTTLES.each do |config|
        expect(described_class).to have_received(:setup_single_throttle).with(**config)
      end
    end
  end
end
