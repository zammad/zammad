# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/migration_scheduler_last_run'

RSpec.describe RuboCop::Cop::Zammad::MigrationSchedulerLastRun, type: :rubocop do

  it 'shows no error for create_if_not_exists when last_run is set' do
    expect_no_offenses(<<-RUBY)
    Scheduler.create_if_not_exists(
      name:          "Clean up 'DataPrivacyTask'.",
      method:        'DataPrivacyTask.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
    RUBY
  end

  it 'shows error for create_if_not_exists when last_run is not set' do
    result = inspect_source(<<~RUBY)
      Scheduler.create_if_not_exists(
        name:          "Clean up 'DataPrivacyTask'.",
        method:        'DataPrivacyTask.cleanup',
        period:        1.day,
        prio:          2,
        active:        true,
        updated_by_id: 1,
        created_by_id: 1,
      )
    RUBY

    expect(result.first.cop_name).to eq('Zammad/MigrationSchedulerLastRun')
  end

  it 'shows no error for create_or_update when last_run is set' do
    expect_no_offenses(<<-RUBY)
    Scheduler.create_or_update(
      name:          "Clean up 'DataPrivacyTask'.",
      method:        'DataPrivacyTask.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.zone.now,
    )
    RUBY
  end

  it 'shows error for create_or_update when last_run is not set' do
    result = inspect_source(<<~RUBY)
      Scheduler.create_or_update(
        name:          "Clean up 'DataPrivacyTask'.",
        method:        'DataPrivacyTask.cleanup',
        period:        1.day,
        prio:          2,
        active:        true,
        updated_by_id: 1,
        created_by_id: 1,
      )
    RUBY

    expect(result.first.cop_name).to eq('Zammad/MigrationSchedulerLastRun')
  end
end
