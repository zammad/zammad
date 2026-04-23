# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Rebuild do
  subject(:service_result) { described_class.execute }

  before do
    setup_ai_provider('open_ai')
  end

  it 'Rebuild vector database table', :aggregate_failures do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    allow(Service::AI::VectorDB::DropTable).to receive(:execute)
    allow(Service::AI::VectorDB::CreateTable).to receive(:execute)
    allow(Service::AI::VectorDB::Reload).to receive(:execute)

    service_result

    expect(Service::AI::VectorDB::DropTable).to have_received(:execute)
    expect(Service::AI::VectorDB::CreateTable).to have_received(:execute)
    expect(Service::AI::VectorDB::Reload).to have_received(:execute)
  end
end
