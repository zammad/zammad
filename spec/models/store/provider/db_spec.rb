# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Store::Provider::DB do
  describe '.add' do
    let(:checksum) { Store::File.checksum(data) }
    let(:data)     { 'bar' }

    before do
      described_class.add(data, checksum)
    end

    it 'adds data to the database' do
      expect(described_class.find_by(sha: checksum))
        .to have_attributes(data:)
    end
  end

  describe '.get' do
    let(:checksum) { Store::File.checksum(data) }
    let(:data)     { 'bar' }

    before do
      described_class.add(data, checksum)
    end

    it 'returns nil when no matching record exists' do
      expect(described_class.get('nonexistentsha')).to be_nil
    end

    it 'returns the data when a matching record exists' do
      expect(described_class.get(checksum)).to eq(data)
    end
  end

  describe '.delete' do
    let(:checksum) { Store::File.checksum(data) }
    let(:data)     { 'bar' }

    before do
      described_class.add(data, checksum)
      described_class.add(data, 'anotherdata')
    end

    it 'returns true when no matching record exists' do
      expect(described_class.delete('nonexistentsha')).to be_truthy
    end

    it 'destroys matching records' do
      expect { described_class.delete(checksum) }
        .to change(described_class, :count)
        .by(-1)
    end
  end

  describe '.change_checksum' do
    let(:initial_data)     { 'foo' }
    let(:new_data)         { 'bar' }
    let(:initial_checksum) { Store::File.checksum(initial_data) }
    let(:new_checksum)     { Store::File.checksum(new_data) }

    before do
      described_class.add(new_data, initial_checksum)
    end

    it 'changes the checksum of the DB record' do
      expect { described_class.change_checksum(initial_checksum, new_checksum) }
        .to change { described_class.last.sha }
        .from(initial_checksum)
        .to(new_checksum)
    end

    it 'can read the new content' do
      described_class.change_checksum(initial_checksum, new_checksum)

      expect(described_class.get(new_checksum)).to eq(new_data)
    end
  end
end
