# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Reachable do
  subject(:service_result) { described_class.execute }

  before do
    setup_ai_provider('open_ai')
  end

  it 'is true where Elasticsearch answers with a supported version' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!).with(only_version: true)

    expect(service_result).to be(true)
  end

  it 'is false where it cannot be reached or the version is unsupported' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!).and_raise(AI::VectorDB::Error, 'nope')

    expect(service_result).to be(false)
  end

  # The index only exists after the first build, so asking for it would answer "no" exactly when the
  # admin is switching semantic search on for the first time.
  it 'asks for the version only, not for the index' do
    expect_any_instance_of(AI::VectorDB).to receive(:ping!).with(only_version: true)

    service_result
  end
end
