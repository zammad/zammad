# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/forbid_default_scope'

RSpec.describe RuboCop::Cop::Zammad::ForbidDefaultScope, type: :rubocop do
  it 'accepts simple order' do
    expect_no_offenses('default_scope { order(:id) }')
  end

  it 'accepts simple order string' do
    expect_no_offenses('default_scope { order("id ASC") }')
  end

  it 'accepts simple order block' do
    expect_no_offenses('default_scope do
       order("id ASC")
    end')
  end

  it 'rejects where statements' do
    result = inspect_source('default_scope { where(active: true) }')

    expect(result.first.cop_name).to eq('Zammad/ForbidDefaultScope')
  end

  it 'rejects where order statements' do
    result = inspect_source('default_scope { where(active: true).order(:id) }')

    expect(result.first.cop_name).to eq('Zammad/ForbidDefaultScope')
  end
end
