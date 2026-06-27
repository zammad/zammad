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
  let(:vector_db)            { instance_double(AI::VectorDB, document_ids: indexed_ids, upsert: nil, delete: nil) }
  let(:cache)                { Service::AI::VectorDB::Embedding::Cache }
  let(:model)                { AI::Provider.current.new.options[:embedding_model] }

  before do
    setup_ai_provider('open_ai')
    allow_any_instance_of(described_class).to receive(:ai_vector_db).and_return(vector_db)
    allow(vector_db).to receive(:build_identifier) { |**args| id_for(args[:content]) }
    # One batched call per upsert; returns one vector per input chunk.
    allow(Service::AI::VectorDB::Embedding).to receive(:execute) { |input:| Array.new(input.size) { embedding } }
  end

  # The content-addressed document id of a chunk, mirroring AI::VectorDB#build_identifier.
  def id_for(text)
    "#{object_name}-#{object_id}-#{Digest::SHA256.hexdigest(text)}"
  end

  context 'with short content (single chunk), nothing indexed yet' do
    it 'embeds the new chunk in one batched call and upserts it with the metadata' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once.with(input: [content])
      expect(vector_db).to have_received(:upsert).once.with(object_id:, object_name:, content:, metadata:, embedding:)
    end

    it 'deletes nothing' do
      upsert

      expect(vector_db).not_to have_received(:delete)
    end
  end

  context 'with long content' do
    let(:content) { Array.new(40) { |i| "This is sentence number #{i} with several words in it." }.join(' ') }

    it 'embeds every new chunk in one batched call and upserts each' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once
      expect(vector_db).to have_received(:upsert).at_least(:twice)
    end
  end

  context 'when the content is unchanged (already embedded and indexed)' do
    let(:indexed_ids) { [id_for(content)] }

    before { cache.write(object_name:, object_id:, model:, vectors: { cache.digest(content, model:) => embedding }) }

    it 'reuses the cached vector instead of re-embedding, but re-upserts to refresh metadata' do
      upsert

      expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      expect(vector_db).to have_received(:upsert).with(object_id:, object_name:, content:, metadata:, embedding:)
    end

    it 'deletes nothing' do
      upsert

      expect(vector_db).not_to have_received(:delete)
    end
  end

  context 'when the embedding model has changed' do
    let(:indexed_ids)   { [id_for(content)] }
    let(:old_embedding) { [9.9, 8.8, 7.7] }

    before { cache.write(object_name:, object_id:, model: 'old-model', vectors: { cache.digest(content, model: 'old-model') => old_embedding }) }

    it 're-embeds instead of reusing the stale vector from the previous model' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(input: [content])
      expect(vector_db).to have_received(:upsert).with(hash_including(content:, embedding:))
    end
  end

  context 'when the content changed (a stale chunk is indexed)' do
    let(:indexed_ids) { [id_for('An old answer.')] }

    it 'removes the stale chunk and embeds + upserts the new one' do
      upsert

      expect(vector_db).to have_received(:delete).with(id: id_for('An old answer.'))
      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).with(input: [content])
      expect(vector_db).to have_received(:upsert).with(hash_including(content:))
    end
  end

  context 'when the index was rebuilt (empty index) but the embedding cache still has the vector' do
    let(:indexed_ids)   { [] } # a full reindex drops the index
    let(:cached_vector) { [0.4, 0.5, 0.6] }

    before { cache.write(object_name:, object_id:, model:, vectors: { cache.digest(content, model:) => cached_vector }) }

    it 'reuses the cached vector instead of paying for the embedding again' do
      upsert

      expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      expect(vector_db).to have_received(:upsert).with(object_id:, object_name:, content:, metadata:, embedding: cached_vector)
    end
  end

  context 'with content_meta_headers' do
    let(:content_meta_headers) { ['How to reset your password'] }
    let(:expected_chunk)       { "How to reset your password\n\n#{content}" }

    it 'prefixes the headers onto the embedded and upserted chunk' do
      upsert

      expect(Service::AI::VectorDB::Embedding).to have_received(:execute).once.with(input: [expected_chunk])
      expect(vector_db).to have_received(:upsert).with(hash_including(content: expected_chunk))
    end
  end

  context 'with empty content' do
    let(:content) { '' }

    context 'with existing chunks' do
      let(:indexed_ids) { [id_for('An old answer.')] }

      it 'removes them and upserts nothing' do
        upsert

        expect(vector_db).to have_received(:delete).with(id: id_for('An old answer.'))
        expect(vector_db).not_to have_received(:upsert)
        expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
      end
    end

    context 'without anything indexed' do
      it 'does nothing' do
        upsert

        expect(vector_db).not_to have_received(:delete)
        expect(vector_db).not_to have_received(:upsert)
      end
    end
  end
end
