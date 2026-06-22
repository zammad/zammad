# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Embedding::Cache, :aggregate_failures do
  let(:object_name) { 'KnowledgeBase::Answer::Translation' }
  let(:object_id)   { 42 }
  let(:model)       { 'text-embedding-3-small' }
  let(:vectors)     { { described_class.digest('chunk a', model:) => [0.1, 0.2] } }

  describe '.digest' do
    it 'is a stable hash of model + text' do
      expect(described_class.digest('hi', model:)).to eq(Digest::SHA256.hexdigest("#{model}\nhi"))
    end

    it 'differs by model, so a model change cannot reuse a wrong-dimension vector' do
      expect(described_class.digest('hi', model: 'a')).not_to eq(described_class.digest('hi', model: 'b'))
    end
  end

  describe '.write / .fetch' do
    it 'stores and returns the vector map for the record' do
      described_class.write(object_name:, object_id:, model:, vectors:)

      expect(described_class.fetch(object_name:, object_id:)).to eq(vectors)
    end

    it 'returns an empty hash when nothing is cached' do
      expect(described_class.fetch(object_name:, object_id:)).to eq({})
    end

    it 'overwrites the whole map so stale digests drop out' do
      described_class.write(object_name:, object_id:, model:, vectors: { 'stale-digest' => [9.9] })
      described_class.write(object_name:, object_id:, model:, vectors:)

      expect(described_class.fetch(object_name:, object_id:)).to eq(vectors)
    end

    it 'keeps a single row per record (version-overwrite, not accumulation)' do
      2.times { described_class.write(object_name:, object_id:, model:, vectors:) }

      rows = AI::StoredResult.where(identifier: described_class::IDENTIFIER, related_object_type: object_name, related_object_id: object_id)
      expect(rows.count).to eq(1)
    end
  end

  describe '.destroy' do
    it "removes the record's cache row" do
      described_class.write(object_name:, object_id:, model:, vectors:)
      described_class.destroy(object_name:, object_id:)

      expect(described_class.fetch(object_name:, object_id:)).to eq({})
    end
  end
end
