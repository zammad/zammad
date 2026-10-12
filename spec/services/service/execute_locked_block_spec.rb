# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ExecuteLockedBlock, :aggregate_failures do
  let(:resource) { "execute_locked_block_spec_#{SecureRandom.uuid}" }
  let(:ttl)      { 10_000 }
  let(:redis)    { Zammad::Service::Redis.new }

  after { redis.del(resource) }

  describe '#execute' do
    subject(:service_result) do
      described_class.execute(resource, ttl) do
        block_calls << described_class.locked?(resource)
        'block result'
      end
    end

    let(:block_calls) { [] }

    it 'runs the block while holding the lock and returns its result' do
      expect(service_result).to eq('block result')
      expect(block_calls).to eq([true])
    end

    it 'releases the lock afterwards' do
      service_result

      expect(described_class.locked?(resource)).to be(false)
    end

    context 'when resource is already locked' do
      before { described_class.lock(resource, ttl) }

      it 'does not run the block and returns nil' do
        expect(service_result).to be_nil
        expect(block_calls).to be_empty
      end
    end
  end

  describe '.lock' do
    it 'locks the resource and returns the lock info' do
      expect(described_class.lock(resource, ttl)).to include(resource: resource, value: be_a(String))
      expect(described_class.locked?(resource)).to be(true)
    end

    context 'when resource is already locked' do
      before { described_class.lock(resource, ttl) }

      it 'returns nil' do
        expect(described_class.lock(resource, ttl)).to be_nil
      end
    end
  end

  describe '.unlock' do
    let!(:lock_info) { described_class.lock(resource, ttl) }

    it 'unlocks the resource' do
      expect(described_class.unlock(lock_info)).to eq(1)
      expect(described_class.locked?(resource)).to be(false)
    end

    context 'when the lock is held by someone else' do
      it 'keeps the resource locked' do
        expect(described_class.unlock(lock_info.merge(value: SecureRandom.uuid))).to eq(0)
        expect(described_class.locked?(resource)).to be(true)
      end
    end
  end

  describe '.locked?' do
    context 'when resource is locked' do
      before { described_class.lock(resource, ttl) }

      it 'returns true' do
        expect(described_class.locked?(resource)).to be(true)
      end
    end

    context 'when resource is not locked' do
      it 'returns false' do
        expect(described_class.locked?(resource)).to be(false)
      end
    end
  end

  describe '.locked!' do
    context 'when resource is locked' do
      before { described_class.lock(resource, ttl) }

      it 'raises an error' do
        expect { described_class.locked!(resource) }.to raise_error(Service::ExecuteLockedBlock::ExecuteLockedBlockError)
      end
    end

    context 'when resource is not locked' do
      it 'returns nil' do
        expect(described_class.locked!(resource)).to be_nil
      end
    end
  end

  describe '.extend' do
    let(:validity) { 60_000 }

    context 'when the lock is held' do
      let!(:lock_info) { described_class.lock(resource, ttl) }

      it 'extends the lock' do
        expect(described_class.extend(lock_info.merge(validity:))).to be(true)
        expect(redis.pttl(resource)).to be > ttl
      end
    end

    context 'when resource is not locked' do
      it 'returns 0' do
        expect(described_class.extend({ resource:, value: SecureRandom.uuid, validity: })).to eq(0)
      end
    end
  end
end
