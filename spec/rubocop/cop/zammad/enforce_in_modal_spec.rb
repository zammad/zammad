# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/enforce_in_modal'

RSpec.describe RuboCop::Cop::Zammad::EnforceInModal, type: :rubocop do

  it 'accepts in_modal' do
    expect_no_offenses('in_modal {}')
  end

  it 'accepts other within calls' do
    expect_no_offenses("within '.my_selector'")
  end

  it 'rejects within ".modal"' do
    expect_offense(<<~RUBY)
      within '.modal'
      ^^^^^^^^^^^^^^^ Prefer `in_modal` over `within '.modal'`.
    RUBY
  end

  it 'rejects within ".modal" with a sub-selector' do
    expect_offense(<<~RUBY)
      within '.modal .some-other-selector'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `in_modal` over `within '.modal'`.
    RUBY
  end

  it 'rejects within ".modal-suffixed"' do
    expect_offense(<<~RUBY)
      within '.modal-dialog'
      ^^^^^^^^^^^^^^^^^^^^^^ Prefer `in_modal` over `within '.modal'`.
    RUBY
  end
end
