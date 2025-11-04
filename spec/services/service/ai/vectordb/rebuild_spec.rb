# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Rebuild do
  before do
    setup_ai_provider('open_ai')
  end

  it 'Rebuild vector database table', :aggregate_failures do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    expect_any_instance_of(Service::AI::VectorDB::DropTable).to receive(:execute)
    expect_any_instance_of(Service::AI::VectorDB::CreateTable).to receive(:execute)
    expect_any_instance_of(Service::AI::VectorDB::Reload).to receive(:execute)

    described_class.new.execute
  end
end
