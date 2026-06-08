# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5908CleanupTicketAIAgentRunningFlags, type: :db_migration do
  it 'runs AIAgent.cleanup_orphan_jobs' do
    allow(AI::Agent).to receive(:cleanup_orphan_jobs)

    migrate

    expect(AI::Agent).to have_received(:cleanup_orphan_jobs)
  end
end
