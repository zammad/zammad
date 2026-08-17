# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::ProviderConnection::Validator::EmbeddingRebuild do
  subject(:validate) { described_class.execute(after: after_configuration) }

  let(:indexed_configuration) { { model: 'text-embedding-3-small', size: 1536 } }
  let(:after_configuration)   { { model: 'text-embedding-3-large', size: 3072 } }

  before do
    Service::AI::VectorDB::Embedding::Configuration.record_indexed(indexed_configuration)
  end

  it 'stops a change that costs the knowledge base its embeddings' do
    expect { validate }.to raise_error(described_class::Error)
  end

  it 'names the validator to skip, so the answer can carry it' do
    expect { validate }.to raise_error(an_instance_of(described_class::Error).and(have_attributes(skip_validator: described_class::IDENTIFIER)))
  end

  it 'lets a change that leaves the embeddings alone through' do
    expect { described_class.execute(after: indexed_configuration.dup) }.not_to raise_error
  end

  # Nothing built means nothing re-created, so there is nothing to warn about - the first build is
  # what switching the vector database on pays for.
  context 'when no index has been built yet' do
    let(:indexed_configuration) { nil }

    it 'lets the change through' do
      expect { validate }.not_to raise_error
    end
  end

  # The warning compares what the index holds against what the save would leave it on, independent of
  # either kill switch: a change made while a feature is off still invalidates the index for whenever
  # it is switched back on, and the automatic rebuild that follows is already confirmed by this.
  context 'when the AI provider and the vector database are both switched off' do
    before do
      Setting.set('ai_provider', false)
      Setting.set('vectordb_enabled', false)
    end

    it 'still warns' do
      expect { validate }.to raise_error(described_class::Error)
    end
  end

  # Semantic search simply stops; the index is left where it is.
  context 'when nothing embeds afterwards' do
    let(:after_configuration) { nil }

    it 'lets the change through' do
      expect { validate }.not_to raise_error
    end
  end
end
