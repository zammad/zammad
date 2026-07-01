# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::SimilaritySearch, :aggregate_failures do
  before do
    setup_ai_provider('open_ai')

    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
  end

  context 'when searching by text' do
    subject(:service_result) { described_class.execute(text: 'text') }

    it 'embeds the text and searches the vector database' do
      allow_any_instance_of(AI::VectorDB).to receive(:knn).and_return('knn response')

      allow_any_instance_of(AI::Provider::OpenAI)
        .to receive(:embed)
        .with(input: 'text')
        .and_return([0.1, 0.2, 0.3])

      expect(service_result).to eq('knn response')
    end
  end

  context 'when searching by a precomputed embedding' do
    subject(:service_result) { described_class.execute(embedding: [0.4, 0.5, 0.6]) }

    it 'searches the vector database with the given embedding without re-embedding' do
      allow_any_instance_of(AI::VectorDB).to receive(:knn).with(embedding: [0.4, 0.5, 0.6], k: 2, filter: {}).and_return('knn response')
      expect_any_instance_of(AI::Provider::OpenAI).not_to receive(:embed)

      expect(service_result).to eq('knn response')
    end
  end
end
