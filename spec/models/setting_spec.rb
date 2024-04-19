# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting, type: :model do
  subject(:setting) { create(:setting) }

  describe '.get' do
    context 'when given a valid Setting#name' do
      it 'returns #state_current[:value]' do
        expect { setting.update(state_current: { value: 'foo' }) }
          .to change { described_class.get(setting.name) }.to('foo')
      end
    end

    context 'when interpolated value was set and cache is still valid' do
      it 'stores interpolated value' do
        create(:setting, name: 'broadcast_test', state: 'test')
        described_class.send(:load) # prewarm cache

        described_class.set('broadcast_test', 'test #{config.fqdn}') # rubocop:disable Lint/InterpolationCheck

        expect(described_class.get('broadcast_test'))
          .to eq("test #{described_class.get('fqdn')}")
      end
    end
  end

  describe '.set' do
    context 'when given a valid Setting#name' do
      it 'sets #state_current = { value: <arg> }' do
        expect { described_class.set(setting.name, 'foo') }
          .to change { setting.reload.state_current }.to({ 'value' => 'foo' })
      end
    end

    context 'when #preferences hash includes a :cache key' do
      subject(:setting) { create(:setting, preferences: { cache: ['foo'] }) }

      before { Rails.cache.write('foo', 'bar') }

      it 'resets the cache key' do
        expect { described_class.set(setting.name, 'baz') }
          .to change { Rails.cache.read('foo') }.to(nil)
      end
    end
  end

  describe '.reset' do
    context 'when given a valid Setting#name' do
      it 'sets #state_current = { value: <orig> } (via #state_initial[:value])' do
        setting.update(state_initial: { value: 'foo' })
        described_class.set(setting.name, 'bar')

        expect { described_class.reset(setting.name) }
          .to change { setting.reload.state_current }.to({ value: 'foo' })
      end
    end
  end

  describe 'attributes' do
    describe '#state_initial' do
      subject(:setting) { build(:setting, state: 'foo') }

      it 'is set on creation, based on #state' do
        expect { setting.save }
          .to change(setting, :state_initial).from({}).to({ value: 'foo' })
      end
    end
  end

  describe 'broadcast_frontend' do
    subject(:setting) do
      build(:setting, name: 'broadcast_test', state: value, frontend: frontend)
        .tap { |setting| setting.preferences = { authentication: true } if authentication_required }
    end

    let(:value)                   { 'foo' }
    let(:frontend)                { true }
    let(:authentication_required) { false }

    context 'when setting is non-frontend' do
      let(:frontend) { false }

      it 'does not broadcast' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).not_to have_received(:broadcast)
      end

      it 'does not trigger subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).not_to have_received(:trigger).with(setting)
      end
    end

    context 'when setting is public' do
      it 'broadcasts to public' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast)
          .with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'public')
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end

    context 'when setting requires authentication' do
      let(:authentication_required) { true }

      it 'broadcasts to authenticated only' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast)
          .with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'authenticated')
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end

    context 'when setting uses interpolation' do
      let(:value) { 'test #{config.fqdn}' } # rubocop:disable Lint/InterpolationCheck

      it 'broadcasts to authenticated only' do
        allow(Sessions).to receive(:broadcast)

        setting.save

        expect(Sessions)
          .to have_received(:broadcast)
          .with(
            { data: { name: 'broadcast_test', value: "test #{described_class.get('fqdn')}" }, event: 'config_update' },
            'public'
          )
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::ConfigUpdates).to receive(:trigger)
        setting.save
        expect(Gql::Subscriptions::ConfigUpdates).to have_received(:trigger).with(setting)
      end
    end
  end
end
