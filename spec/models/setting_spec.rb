# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

    context 'with offending chars in product_name and fqdn (#4355)' do
      before do
        described_class.set('product_name', '<My "Helpdesk">')
        described_class.set('fqdn', 'localhost:8080')
      end

      it 'sanitizes notification_sender value' do
        expect(described_class.get('notification_sender'))
          .to eq('"<My \'\'Helpdesk\'\'>" <noreply@localhost>')
      end
    end
  end

  describe '.set' do
    context 'when given a valid Setting#name' do
      it 'sets #state_current = { value: <arg> }' do
        expect { described_class.set(setting.name, 'foo') }
          .to change { setting.reload.state_current }.to({ 'value' => 'foo' })
      end

      it 'logs the value' do
        allow(described_class.logger).to receive(:info)
        described_class.set(setting.name, 'foo')
        expect(described_class.logger).to have_received(:info).with("Setting.set('#{setting.name}', \"foo\")")
      end
    end

    context 'when given a sensitive Setting#name' do
      subject(:setting) { create(:setting, name: 'my_token') }

      it 'masks the value' do
        allow(described_class.logger).to receive(:info)
        described_class.set(setting.name, 'foo')
        expect(described_class.logger).to have_received(:info).with("Setting.set('#{setting.name}', \"[FILTERED]\")")
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

      it 'logs the value' do
        setting.update(state_initial: { value: 'foo' })
        allow(described_class.logger).to receive(:info)
        described_class.reset(setting.name)
        expect(described_class.logger).to have_received(:info).with("Setting.reset('#{setting.name}', {\"value\"=>\"foo\"})")
      end
    end

    context 'when given a sensitive Setting#name' do
      subject(:setting) { create(:setting, name: 'my_token') }

      it 'masks the value' do
        setting.update(state_initial: { value: 'foo' })
        allow(described_class.logger).to receive(:info)
        described_class.reset(setting.name)
        expect(described_class.logger).to have_received(:info).with("Setting.reset('#{setting.name}', \"[FILTERED]\")")
      end
    end

  end

  describe '.cache_valid?' do
    context 'when loading first time' do
      before do
        # ensure no cache checks are set
        described_class.class_variable_set(:@@lookup_at, nil) # rubocop:disable Style/ClassVars
        described_class.class_variable_set(:@@query_cache_key, nil) # rubocop:disable Style/ClassVars
      end

      it 'cache is not valid' do
        expect(described_class).not_to be_cache_valid
      end
    end

    context 'when cache is valid' do
      before do
        # ensure cache is warm
        described_class.send(:load)

        # ensure cache is not touched by broadcasting the new value
        allow_any_instance_of(described_class).to receive(:broadcast_frontend)
      end

      it 'cache is valid' do
        expect(described_class).to be_cache_valid
      end

      it 'cache is still valid after some time' do
        travel 1.minute
        expect(described_class).to be_cache_valid
      end

      context 'when Setting is updated in the same process' do
        before { described_class.set('maintenance_login', 'sample message') }

        it 'cache is not valid' do
          expect(described_class).not_to be_cache_valid
        end
      end

      context 'when Setting updated outside of the process and class variables were not touched' do
        before { described_class.find_by(name: 'maintenance_login').touch }

        it 'cache is seen as valid' do
          expect(described_class).to be_cache_valid
        end

        it 'cache is seen as invalid after some time' do
          travel 1.minute
          expect(described_class).not_to be_cache_valid
        end
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
