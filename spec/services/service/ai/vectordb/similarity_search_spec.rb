# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::SimilaritySearch do
  before do
    setup_ai_provider('open_ai')
  end

  it 'Rebuild vector database table' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    allow_any_instance_of(AI::VectorDB).to receive(:knn).and_return('knn response')

    allow_any_instance_of(AI::Provider::OpenAI)
      .to receive(:embeddings)
      .with(input: 'text')
      .and_return('test embedding')

    expect(described_class.new(text: 'text').execute).to eq('knn response')
  end
end
