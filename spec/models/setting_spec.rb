# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

      before { Cache.write('foo', 'bar') }

      it 'resets the cache key' do
        expect { described_class.set(setting.name, 'baz') }
          .to change { Cache.read('foo') }.to(nil)
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
end
