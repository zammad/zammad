# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::VectorDB::Reload do
  subject(:service_result) { described_class.execute }

  before do
    setup_ai_provider('open_ai')
  end

  it 'Rebuild vector database table' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    allow(KnowledgeBase::Answer::Translation).to receive(:vector_index_reload)

    service_result

    expect(KnowledgeBase::Answer::Translation).to have_received(:vector_index_reload).once
  end
end
