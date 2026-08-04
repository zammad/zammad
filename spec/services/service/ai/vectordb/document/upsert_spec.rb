# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Document::Upsert, :aggregate_failures do
  subject(:upsert) { described_class.execute(object_name:, object_id:, content:, content_meta_headers:, metadata:) }

  let(:object_name)          { 'KnowledgeBase::Answer::Translation' }
  let(:object_id)            { 42 }
  let(:content_meta_headers) { [] }
  let(:metadata)             { { locale: 'en-us', category_id: 7 } }
  let(:content)              { 'A short answer.' }
  let(:embedding)            { [0.1, 0.2, 0.3] }
  let(:indexed_ids)          { [] } # ids currently in the index (AI::VectorDB#document_ids)
  let(:vector_db)            { instance_double(AI::VectorDB, document_ids: indexed_ids) }
  let(:bulk_calls)           { [] }
  let(:metadata_patches)     { [] }
  let(:cache)                { Service::AI::VectorDB::Embedding::Cache }
  let(:model)                { AI::ProviderConnection.for_embeddings.provider_instance.options[:embedding_model] }

  before do
    setup_ai_provider('open_ai', token: 'secret-token')
    allow_any_instance_of(described_class).to receive(:ai_vector_db).and_return(vector_db)
    allow(vector_db).to receive(:build_identifier) { |**args| id_for(args[:content]) }
    allow(vector_db).to receive(:bulk) { |**kwargs| bulk_calls << kwargs }
    allow(vector_db).to receive(:update_metadata) { |**kwargs| metadata_patches << kwargs }
    # One batched embedding call; returns one vector per input chunk.
    allow(Service::AI::VectorDB::Embedding).to receive(:execute) { |input:, **| Array.new(input.size) { embedding } }
  end

  # The content-addressed document id of a chunk, mirroring AI::VectorDB#build_identifier.
  def id_for(text)
    "#{object_name}-#{object_id}-#{Digest::SHA256.hexdigest(text)}"
  end

  # The upsert op Upsert builds per chunk for AI::VectorDB#bulk.
  def upsert_op(chunk, vector: embedding)
    { object_id:, object_name:, content: chunk, embedding: vector, metadata: }
  end

  # The single bulk / metadata-patch call the service is expected to make.
  def bulk_call
    expect(bulk_calls.size).to eq(1)
    bulk_calls.first
  end

  context 'with new content (no matching chunks indexed yet)' do
    it 'embeds the new chunk and writes it in one bulk request' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once.with(input: [content])
      expect(bulk_call[:upserts]).to eq([upsert_op(content)])
      expect(bulk_call[:deletes]).to eq([])
      expect(metadata_patches).to be_empty
    end
  end

  context 'with long content' do
    let(:content) { Array.new(40) { |i| "This is sentence number #{i} with several words in it." }.join(' ') }

    it 'embeds every new chunk in one batched call and writes them in one bulk request' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once
      expect(bulk_call[:upserts].size).to be >= 2
      expect(bulk_call[:deletes]).to be_empty
    end
  end

  context 'when the same chunks are already indexed (only metadata could have changed)' do
    let(:indexed_ids) { [id_for(content)] }

    it 'patches the metadata in place — no re-embedding, no chunk rewrite' do
      upsert

      expect(metadata_patches).to eq([{ object_id:, object_name:, metadata: }])
      expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      expect(bulk_calls).to be_empty
    end
  end

  context 'when the content changed (a stale chunk is indexed)' do
    let(:indexed_ids) { [id_for('An old answer.')] }

    it 'removes the stale chunk and embeds + upserts the new one in one bulk request' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(input: [content])
      expect(bulk_call[:upserts]).to eq([upsert_op(content)])
      expect(bulk_call[:deletes]).to eq([id_for('An old answer.')])
      expect(metadata_patches).to be_empty
    end
  end

  context 'when the index was rebuilt (empty index) but the embedding cache still has the vector' do
    let(:indexed_ids)   { [] } # a full reindex drops the index
    let(:cached_vector) { [0.4, 0.5, 0.6] }

    before { cache.write(object_name:, object_id:, model:, vectors: { cache.digest(content, model:) => cached_vector }) }

    it 'reuses the cached vector instead of paying for the embedding again' do
      upsert

      expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      expect(bulk_call[:upserts]).to eq([upsert_op(content, vector: cached_vector)])
    end
  end

  context 'when the membership check is skipped (rebuild onto a fresh, empty index)' do
    subject(:upsert) do
      described_class.execute(object_name:, object_id:, content:, content_meta_headers:, metadata:, skip_membership_check: true)
    end

    # A stale chunk would normally be discovered by the membership search and deleted; with the
    # check skipped we must NOT search, and the full path runs with no deletes (the index is empty).
    let(:indexed_ids) { [id_for('An old answer.')] }

    it 'goes straight to the full path without the membership search' do
      upsert

      expect(vector_db).not_to have_received(:document_ids)
      expect(metadata_patches).to be_empty
      expect(bulk_call[:upserts]).to eq([upsert_op(content)])
      expect(bulk_call[:deletes]).to eq([])
    end
  end

  context 'with content_meta_headers' do
    let(:content_meta_headers) { ['How to reset your password'] }
    let(:expected_chunk)       { "How to reset your password\n\n#{content}" }

    it 'prefixes the headers onto the embedded and upserted chunk' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once.with(input: [expected_chunk])
      expect(bulk_call[:upserts]).to eq([upsert_op(expected_chunk)])
    end
  end

  context 'with empty content' do
    let(:content) { '' }

    context 'with existing chunks' do
      let(:indexed_ids) { [id_for('An old answer.')] }

      it 'removes them and upserts nothing' do
        upsert

        expect(bulk_call[:upserts]).to eq([])
        expect(bulk_call[:deletes]).to eq([id_for('An old answer.')])
        expect(metadata_patches).to be_empty
        expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      end
    end

    context 'without anything indexed' do
      it 'does nothing' do
        upsert

        expect(bulk_call[:upserts]).to eq([])
        expect(bulk_call[:deletes]).to eq([])
        expect(metadata_patches).to be_empty
      end
    end
  end
end
