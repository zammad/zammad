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

  it 'forwards the fresh flag to the per-model reload' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    allow(KnowledgeBase::Answer::Translation).to receive(:vector_index_reload)

    described_class.execute(fresh: true)

    expect(KnowledgeBase::Answer::Translation).to have_received(:vector_index_reload).with(worker: 0, fresh: true, abort_when: nil)
  end

  it 'forwards the abort condition to the per-model reload' do
    allow_any_instance_of(AI::VectorDB).to receive(:ping!)
    allow(KnowledgeBase::Answer::Translation).to receive(:vector_index_reload)
    abort_when = -> { false }

    described_class.execute(abort_when:)

    expect(KnowledgeBase::Answer::Translation).to have_received(:vector_index_reload).with(worker: 0, fresh: false, abort_when:)
  end

  # A reload embeds one document at a time for however long the knowledge base is - a run that has
  # become obsolete stops between documents instead of finishing what a successor throws away.
  it 'stops between records once the run is obsolete', :aggregate_failures do
    create_list(:knowledge_base_answer, 2)

    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
    allow(KnowledgeBase::Answer::Translation).to receive(:vector_index_scope).and_return(KnowledgeBase::Answer::Translation.all)

    updated = 0
    allow_any_instance_of(KnowledgeBase::Answer::Translation).to receive(:vector_index_update) { updated += 1 }

    checks     = [false, true]
    abort_when = -> { checks.shift }

    expect { KnowledgeBase::Answer::Translation.vector_index_reload(abort_when:) }
      .to raise_error(Service::AI::VectorDB::Reload::Aborted)
    expect(updated).to eq(1)
  end
end
