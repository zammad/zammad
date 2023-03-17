# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when given a processed setting key' do
      it 'returns processed value' do
        expect(described_class.get('timezone_default_sanitized')).to be_present
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

  describe 'check_broadcast' do
    context 'when setting is non-frontend' do
      subject(:setting) { build(:setting, name: 'broadcast_test', state: 'foo', frontend: false) }

      it 'does not broadcast' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).not_to have_received(:broadcast)
      end
    end

    context 'when setting is public' do
      subject(:setting) { build(:setting, name: 'broadcast_test', state: 'foo', frontend: true) }

      it 'broadcasts to public' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast).with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'public')
      end
    end

    context 'when setting requires authentication' do
      subject(:setting) { build(:setting, name: 'broadcast_test', state: 'foo', frontend: true, preferences: { authentication: true }) }

      it 'broadcasts to authenticated only' do
        allow(Sessions).to receive(:broadcast)
        setting.save
        expect(Sessions).to have_received(:broadcast).with({ data: { name: 'broadcast_test', value: 'foo' }, event: 'config_update' }, 'authenticated')
      end
    end
  end
end
