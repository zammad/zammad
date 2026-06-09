# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Item::Upsert do
  subject(:service_result) { described_class.execute(object_id: object.id, object_name: object.class.name, content: 'Test content', metadata: :metadata) }

  let(:object)    { create(:ticket) }
  let(:embedding) { [0.1, 0.2, 0.3] }

  before do
    setup_ai_provider('open_ai')
  end

  it 'Upserts a vector database item' do
    allow_any_instance_of(AI::Provider::OpenAI).to receive(:embed).and_return(embedding)

    expect_any_instance_of(AI::VectorDB)
      .to receive(:upsert)
      .with(object_id: object.id, object_name: object.class.name, content: 'Test content', metadata: :metadata, embedding:)

    service_result
  end
end
