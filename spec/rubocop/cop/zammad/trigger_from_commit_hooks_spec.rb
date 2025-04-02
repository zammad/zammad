# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/trigger_from_commit_hooks'

RSpec.describe RuboCop::Cop::Zammad::TriggerFromCommitHooks, :aggregate_failures, type: :rubocop do

  it 'accepts triggers from commit hooks' do
    expect_no_offenses('after_create_commit :trigger_subscriptions')
    expect_no_offenses('after_update_commit :trigger_subscriptions')
    expect_no_offenses('after_save_commit :trigger_subscriptions')
    expect_no_offenses('after_destroy_commit :trigger_subscriptions')
    expect_no_offenses('after_commit :trigger_subscriptions')
  end

  it 'ignores other callback methods' do
    expect_no_offenses('after_save :other_callback')
  end

  it 'rejects triggers from non-commit hooks' do
    expect_offense(<<~RUBY)
      after_create :trigger_subscriptions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trigger GraphQL subscriptions only from commit hooks to ensure the data is available in other processes.
    RUBY
    expect_correction(<<~RUBY)
      after_create_commit :trigger_subscriptions
    RUBY
    expect_offense(<<~RUBY)
      after_update :trigger_subscriptions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trigger GraphQL subscriptions only from commit hooks to ensure the data is available in other processes.
    RUBY
    expect_correction(<<~RUBY)
      after_update_commit :trigger_subscriptions
    RUBY
    expect_offense(<<~RUBY)
      after_save :trigger_subscriptions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trigger GraphQL subscriptions only from commit hooks to ensure the data is available in other processes.
    RUBY
    expect_correction(<<~RUBY)
      after_save_commit :trigger_subscriptions
    RUBY
    expect_offense(<<~RUBY)
      after_destroy :trigger_subscriptions
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Trigger GraphQL subscriptions only from commit hooks to ensure the data is available in other processes.
    RUBY
    expect_correction(<<~RUBY)
      after_destroy_commit :trigger_subscriptions
    RUBY
  end
end
