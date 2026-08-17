# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::DropTable do
  subject(:service_result) { described_class.execute }

  before do
    setup_ai_provider('open_ai')
  end

  it 'Drop vector database table' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    expect_any_instance_of(AI::VectorDB).to receive(:drop)

    service_result
  end

  # The full ping! raises where the index does not exist - which is no reason not to drop: a rebuild
  # starts here, so the first build ever would otherwise be impossible.
  it 'drops without requiring an index to be there', :aggregate_failures do
    expect_any_instance_of(AI::VectorDB).to receive(:ping!).with(only_version: true)
    expect_any_instance_of(AI::VectorDB).to receive(:drop)

    service_result
  end
end
