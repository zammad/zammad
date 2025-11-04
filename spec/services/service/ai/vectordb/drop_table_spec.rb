# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::DropTable do
  before do
    setup_ai_provider('open_ai')
  end

  it 'Drop vector database table' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    expect_any_instance_of(AI::VectorDB).to receive(:drop)

    described_class.new.execute
  end
end
