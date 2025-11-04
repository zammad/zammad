# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Available do
  before do
    setup_ai_provider('open_ai')
  end

  it 'Checks if vector database is available' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping?).and_return(:ping)

    expect(described_class.new.execute).to be :ping
  end
end
