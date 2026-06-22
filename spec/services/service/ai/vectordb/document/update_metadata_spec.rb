# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Document::UpdateMetadata, :aggregate_failures do
  subject(:update_metadata) { described_class.execute(object_name:, object_id:, metadata:) }

  let(:object_name) { 'KnowledgeBase::Answer::Translation' }
  let(:object_id)   { 42 }
  let(:metadata)    { { locale: 'en-us', category_id: 7, visible_internally: true } }
  let(:response)    { { 'total' => 3, 'updated' => 3 } }
  let(:vector_db)   { instance_double(AI::VectorDB, update_metadata: response) }

  before do
    setup_ai_provider('open_ai')
    allow_any_instance_of(described_class).to receive(:ai_vector_db).and_return(vector_db)
  end

  it 'calls update_metadata on the vector DB with the correct arguments' do
    update_metadata

    expect(vector_db).to have_received(:update_metadata).with(
      object_id:   object_id,
      object_name: object_name,
      metadata:    metadata
    )
  end

  it 'returns the number of matched documents' do
    expect(update_metadata).to eq(3)
  end

  it 'does not touch embeddings or chunking' do
    allow(Service::AI::VectorDB::Embedding).to receive(:execute)
    update_metadata

    expect(Service::AI::VectorDB::Embedding).not_to have_received(:execute)
  end

  context 'when no documents are indexed for the record' do
    let(:response) { { 'total' => 0, 'updated' => 0 } }

    it 'returns zero so the caller can fall back to a full embed' do
      expect(update_metadata).to eq(0)
    end
  end
end
