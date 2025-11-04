# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Item::Upsert do
  let(:object) { create(:ticket) }

  before do

    setup_ai_provider('open_ai')
  end

  it 'Upserts a vector database item' do
    allow_any_instance_of(AI::Provider::OpenAI).to receive(:embeddings).and_return('test embedding')

    expect_any_instance_of(AI::VectorDB)
      .to receive(:upsert)
      .with(object_id: object.id, object_name: object.class.name, content: 'Test content', metadata: :metadata, embedding: 'test embedding')

    described_class
      .new(object_id: object.id, object_name: object.class.name, content: 'Test content', metadata: :metadata)
      .execute
  end
end
