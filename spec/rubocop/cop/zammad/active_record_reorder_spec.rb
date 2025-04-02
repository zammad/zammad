# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/active_record_reorder'

RSpec.describe RuboCop::Cop::Zammad::ActiveRecordReorder, :aggregate_failures, type: :rubocop do

  it 'accepts reorder calls' do
    expect_no_offenses('Ticket.where(state: open_states).reorder(:id)')
    expect_no_offenses('overview.order[:by]')
    expect_no_offenses('default_scope { order(:prio, :id) }')
    expect_no_offenses('scope :sorted, -> { order(position: :asc) }')
  end

  it 'rejects order calls' do
    expect_offense(<<~RUBY)
      Ticket.where(state: open_states).order(:id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer 'reorder' over 'order' to prevent issues with default ordering.
    RUBY
    expect_correction(<<~RUBY)
      Ticket.where(state: open_states).reorder(:id)
    RUBY
  end
end
