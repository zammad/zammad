# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  describe '.stream' do
    let(:checksum) { Store::File.checksum(data) }
    let(:data)     { "#{"foo\x00bar" * 3}\n\n\n\n".b }

    before do
      stub_const("#{described_class}::CHUNK_SIZE", 4)
      described_class.add(data, checksum)
    end

    it 'yields the content in chunks' do
      expect { |block| described_class.stream(checksum, &block) }
        .to yield_successive_args(*data.scan(%r{.{1,4}}m))
    end

    it 'does not keep the chunks in the query cache' do
      described_class.cache do
        described_class.stream(checksum) { nil }

        expect(described_class.connection.query_cache.size).to eq(1)
      end
    end

    it 'raises an error when the content ends before its announced size' do
      allow(described_class).to receive(:bytesize).and_return(data.bytesize + 4)

      expect { described_class.stream(checksum) { nil } }
        .to raise_error(RuntimeError, %r{ended after #{data.bytesize} of #{data.bytesize + 4} bytes})
    end

    it 'yields nothing when no matching record exists' do
      expect { |block| described_class.stream('nonexistentsha', &block) }
        .not_to yield_control
    end
  end

  describe '.bytesize' do
    let(:checksum) { Store::File.checksum(data) }
    let(:data)     { "foo\x00bar".b }

    before do
      described_class.add(data, checksum)
    end

    it 'returns the size of the stored data' do
      expect(described_class.bytesize(checksum)).to eq(data.bytesize)
    end

    it 'returns nil when no matching record exists' do
      expect(described_class.bytesize('nonexistentsha')).to be_nil
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
