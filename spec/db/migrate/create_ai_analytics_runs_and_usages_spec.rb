# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CreateAIAnalyticsRunsAndUsages, db_strategy: :reset, type: :db_migration do
  before do
    create(:ai_stored_result)

    remove_column :ai_stored_results, :ai_analytics_run_id
    drop_table :ai_analytics_usages
    drop_table :ai_analytics_runs
  end

  it 'clears AI::StoredResult records' do
    expect { migrate }.to change(AI::StoredResult, :count).from(1).to(0)
  end
end
