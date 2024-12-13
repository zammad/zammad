# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AppVersion, :aggregate_failures do

  describe '.get' do
    it 'returns the value of the "app_version" setting' do
      Setting.set('app_version', 'mytimestamp')
      expect(described_class.get).to eq('mytimestamp')
    end
  end

  describe '.trigger_browser_reload' do
    before do
      allow(Sessions).to receive(:broadcast)
      allow(Gql::Subscriptions::AppMaintenance).to receive(:trigger)
    end

    it 'updates the version and publishes it' do
      expect { described_class.trigger_browser_reload(AppVersion::MSG_CONFIG_CHANGED) }
        .to change(described_class, :get)
      expect(Sessions).to have_received(:broadcast)
      expect(Gql::Subscriptions::AppMaintenance).to have_received(:trigger)
    end
  end

  describe '.trigger_restart' do
    let(:auto_shutdown) { true }

    before do
      Setting.set('auto_shutdown', auto_shutdown)
      allow(described_class).to receive(:trigger_browser_reload)
      allow(described_class).to receive(:restart_required!)
    end

    context 'with auto_shutdown' do
      it 'triggers browser reload' do
        described_class.trigger_restart
        expect(described_class).to have_received(:trigger_browser_reload).with(AppVersion::MSG_RESTART_AUTO, anything)
        expect(described_class).to have_received(:restart_required!)
      end
    end

    context 'without auto_shutdown' do
      let(:auto_shutdown) { false }

      it 'triggers browser reload' do
        described_class.trigger_restart
        expect(described_class)
          .to have_received(:trigger_browser_reload).with(AppVersion::MSG_RESTART_MANUAL, anything)
        expect(described_class).not_to have_received(:restart_required!)
      end
    end
  end

  describe '.restart_required!' do
    it 'writes to Redis' do
      allow_any_instance_of(Redis).to receive(:set)
      described_class.send(:restart_required!, 'mytimestamp')
      expect(described_class.send(:redis))
        .to have_received(:set)
        .with(AppVersion::REDIS_RESTART_REQUIRED_KEY, 'mytimestamp', ex: AppVersion::REDIS_RESTART_REQUIRED_TTL)
    end
  end

  describe '.restart_required?' do
    before do
      allow_any_instance_of(Redis).to receive(:get).and_return(redis_value)
    end

    let(:known_value) { 'mytimestamp' }

    context 'when Redis has the same value' do
      let(:redis_value) { 'mytimestamp' }

      it 'returns false' do
        expect(described_class.send(:restart_required?, known_value)).to be(false)
      end
    end

    context 'when Redis has no value' do
      let(:redis_value) { nil }

      it 'returns false' do
        expect(described_class.send(:restart_required?, known_value)).to be(false)
      end
    end

    context 'when Redis has a different value' do
      let(:redis_value) { 'changed_value' }

      it 'returns true' do
        expect(described_class.send(:restart_required?, known_value)).to be(true)
      end
    end
  end

  describe '.start_maintenance_thread' do
    let(:auto_shutdown) { true }

    before do
      Setting.set('auto_shutdown', auto_shutdown)
      allow(described_class).to receive(:restart_required?)
    end

    context 'without auto_shutdown' do
      let(:auto_shutdown) { false }

      it 'does not start a thread' do
        expect(described_class.start_maintenance_thread(process_name: 'rspec')).to be_nil
      end
    end

    context 'with auto_shutdown' do
      it 'starts a thread and calls .restart_required?' do
        thread = described_class.start_maintenance_thread(process_name: 'rspec')
        expect(thread).to be_alive
        sleep 1 # wait for thread to start working
        expect(described_class)
          .to have_received(:restart_required?)
          .with(Setting.get('app_version'))
      ensure
        thread.kill
        thread.join
      end
    end
  end
end
