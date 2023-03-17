# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::HealthChecker::Channels do
  let(:instance) { described_class.new }
  let(:channel1) { create(:email_channel, area: 'testarea') }
  let(:channel2) { create(:email_channel) }

  before do
    Channel.destroy_all
  end

  describe '#check_health' do
    it 'calls channel check' do
      channel1
      allow(instance).to receive(:single_channel_check)
      instance.check_health
      expect(instance).to have_received(:single_channel_check).with(channel1)
    end
  end

  describe '#scope' do
    it 'returns active channels' do
      channel1
      channel2.update!(active: false)

      expect(instance.send(:scope)).to eq [channel1]
    end
  end

  describe '#single_channel_check' do
    before do
      allow(instance).to receive(:status_in)
      allow(instance).to receive(:status_out)
      allow(instance).to receive(:last_fetch)

      instance.send(:single_channel_check, channel1)
    end

    it 'checks status in' do
      expect(instance).to have_received(:status_in).with(channel1)
    end

    it 'checks status out' do
      expect(instance).to have_received(:status_out).with(channel1)
    end

    it 'checks status last fetch' do
      expect(instance).to have_received(:last_fetch).with(channel1)
    end
  end

  describe '#status_in' do
    it 'does nothing if status is not error' do
      instance.send(:status_in, channel1)

      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if status is error' do
      channel1.status_in = 'error'

      instance.send(:status_in, channel1)

      expect(instance.response.issues).to be_present
    end
  end

  describe '#status_out' do
    it 'does nothing if status is not error' do
      instance.send(:status_out, channel1)

      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if status is error' do
      channel1.status_out = 'error'

      instance.send(:status_out, channel1)

      expect(instance.response.issues).to be_present
    end
  end

  describe '#status_message' do
    it 'includes channel name and direction' do
      message = instance.send(:status_message, channel1, :dir)
      expect(message).to start_with('Channel: testarea dir')
    end

    it 'includes present keys' do
      channel1.options = { 'host' => 'example.com', 'uid' => 123 }

      message = instance.send(:status_message, channel1, :dir)

      expect(message).to end_with('host:example.com;uid:123;')
    end
  end

  describe '#last_fetch' do
    it 'does nothing if last fetch is not present' do
      channel1.preferences['last_fetch'] = nil
      instance.send(:last_fetch, channel1)
      expect(instance.response.issues).to be_blank
    end

    it 'does nothing if last fetch is within tolerance' do
      channel1.preferences['last_fetch'] = 30.minutes.ago
      instance.send(:last_fetch, channel1)
      expect(instance.response.issues).to be_blank
    end

    it 'adds issue if last fetch is too long ago' do
      channel1.preferences['last_fetch'] = 30.hours.ago
      instance.send(:last_fetch, channel1)
      expect(instance.response.issues.first).to end_with('is active but not fetched for 1 day')
    end
  end
end
