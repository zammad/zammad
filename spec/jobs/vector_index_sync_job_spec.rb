# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe VectorIndexSyncJob, :aggregate_failures, type: :job do
  subject(:perform_job) { described_class.perform_now }

  before do
    setup_ai_provider
    Setting.set('vectordb_enabled', true)

    # Switching it on reconciles by itself now (Setting#schedule_vector_index_reconcile) - cleared, so
    # this spec still tests what the job does rather than what the setting already did.
    clear_jobs
  end

  # The rebuild job decides for itself between a cheap reload and a full rebuild, off what the index
  # was last built with - this only has to hand over to it.
  it 'hands the index over to the rebuild job' do
    expect { perform_job }.to have_enqueued_job(VectorIndexRebuildJob)
  end

  context 'when the vector database was disabled before the job runs' do
    before do
      Setting.set('vectordb_enabled', false)
    end

    it 'does not change the index' do
      expect { perform_job }.not_to have_enqueued_job(VectorIndexRebuildJob)
    end
  end
end
