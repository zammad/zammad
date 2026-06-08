# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Available do
  subject(:service_result) { described_class.execute }

  before do
    setup_ai_provider('open_ai')
  end

  it 'Checks if vector database is available' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping?).and_return(:ping)

    expect(service_result).to be :ping
  end
end
