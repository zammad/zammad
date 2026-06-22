# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Document::Destroy do
  let(:object) { create(:ticket) }

  before { setup_ai_provider('open_ai') }

  it 'removes all of the document\'s vectors' do
    expect_any_instance_of(AI::VectorDB)
      .to receive(:destroy)
      .with(object_id: object.id, object_name: object.class.name)

    described_class.execute(object_id: object.id, object_name: object.class.name)
  end

  it 'leaves the embedding cache in place (it is cleared only when the record is destroyed)' do
    allow_any_instance_of(AI::VectorDB).to receive(:destroy)
    Service::AI::VectorDB::Embedding::Cache.write(object_name: object.class.name, object_id: object.id, model: 'm', vectors: { 'd' => [1.0] })

    described_class.execute(object_id: object.id, object_name: object.class.name)

    expect(Service::AI::VectorDB::Embedding::Cache.fetch(object_name: object.class.name, object_id: object.id)).to eq({ 'd' => [1.0] })
  end

  it 'removes the embedding cache when the record itself is destroyed (dependent: :destroy)' do
    Service::AI::VectorDB::Embedding::Cache.write(object_name: object.class.name, object_id: object.id, model: 'm', vectors: { 'd' => [1.0] })

    object.destroy

    expect(Service::AI::VectorDB::Embedding::Cache.fetch(object_name: object.class.name, object_id: object.id)).to eq({})
  end
end
