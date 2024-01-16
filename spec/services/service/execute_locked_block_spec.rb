# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ExecuteLockedBlock, :aggregate_failures do

  describe '#execute' do
    subject(:object) { described_class.new(resource, ttl) }

    let(:resource) { 'resource' }
    let(:ttl)      { 1 }
    let(:block)    { proc { true } }

    it 'return block result' do
      allow_any_instance_of(Redlock::Client).to receive(:lock).with(resource, ttl, &block).and_return(true)

      expect(object.execute(&block)).to be(true)
    end

    context 'when resource is already locked' do
      it 'returns nil' do
        allow_any_instance_of(Redlock::Client).to receive(:lock).with(resource, ttl, &block).and_return(nil)

        expect(object.execute(&block)).to be_nil
      end
    end
  end

  describe '.lock' do
    let(:resource) { 'resource' }
    let(:ttl)      { 1 }
    let(:lock_info) do
      {
        resource: resource,
        value:    SecureRandom.uuid,
      }
    end

    it 'returns the lock info' do
      allow_any_instance_of(Redlock::Client).to receive(:lock).with(resource, ttl).and_return(lock_info)

      expect(described_class.lock(resource, ttl)).to be(lock_info)
    end

    context 'when resource is already locked' do
      it 'returns nil' do
        allow_any_instance_of(Redlock::Client).to receive(:lock).with(resource, ttl).and_return(nil)

        expect(described_class.lock(resource, ttl)).to be_nil
      end
    end
  end

  describe '.unlock' do
    let(:resource) { 'resource' }
    let(:lock_info) do
      {
        resource: resource,
        value:    SecureRandom.uuid,
      }
    end

    it 'returns true' do
      allow_any_instance_of(Redlock::Client).to receive(:unlock).with(lock_info).and_return(1)

      expect(described_class.unlock(lock_info)).to be(1)
    end

    context 'when resource can not be unlocked' do
      it 'returns false' do
        allow_any_instance_of(Redlock::Client).to receive(:unlock).with(lock_info).and_return(0)

        expect(described_class.unlock(lock_info)).to be(0)
      end
    end
  end

  describe '.locked?' do
    let(:resource) { 'resource' }
    let(:lock_info) do
      {
        resource: resource,
        value:    SecureRandom.uuid,
      }
    end

    context 'when resource is locked' do
      it 'returns true' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(true)

        expect(described_class.locked?(resource)).to be(true)
      end
    end

    context 'when resource is not locked' do
      it 'returns false' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(false)

        expect(described_class.locked?(resource)).to be(false)
      end
    end
  end

  describe '.locked!' do
    let(:resource) { 'resource' }
    let(:lock_info) do
      {
        resource: resource,
        value:    SecureRandom.uuid,
      }
    end

    context 'when resource is locked' do
      it 'raises an error' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(true)

        expect { described_class.locked!(resource) }.to raise_error(Service::ExecuteLockedBlock::ExecuteLockedBlockError)
      end
    end

    context 'when resource is not locked' do
      it 'returns false' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(false)

        expect(described_class.locked!(resource)).to be_nil
      end
    end
  end

  describe '.extend' do
    let(:lock_info) do
      {
        resource: 'resource',
        value:    SecureRandom.uuid,
        validity: 1,
      }
    end

    it 'returns true' do
      allow_any_instance_of(Redlock::Client).to receive(:lock).with(nil, nil, extend: lock_info).and_return(1)

      expect(described_class.extend(lock_info)).to be(1)
    end

    context 'when resource can not be extended' do
      it 'returns false' do
        allow_any_instance_of(Redlock::Client).to receive(:lock).with(nil, nil, extend: lock_info).and_return(0)

        expect(described_class.extend(lock_info)).to be(0)
      end
    end
  end
end
