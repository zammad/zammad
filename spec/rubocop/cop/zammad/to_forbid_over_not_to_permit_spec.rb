# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/to_forbid_over_not_to_permit'

RSpec.describe RuboCop::Cop::Zammad::ToForbidOverNotToPermit, type: :rubocop do

  it 'accepts to permit_action' do
    expect_no_offenses('is_expected.to permit_action(:test)')
  end

  it 'accepts to permit_actions' do
    expect_no_offenses('expect(instance).to permit_actions :test')
  end

  it 'rejects not_to permit_action' do
    expect_offense(<<~RUBY)
      is_expected.not_to permit_action(:test)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `.to forbid_action[s]` over `.not_to permit_action[s]`.
    RUBY
    expect_correction(<<~RUBY)
      is_expected.to forbid_action(:test)
    RUBY
  end

  it 'rejects not_to permit_actions' do
    expect_offense(<<~RUBY)
      expect(instance).not_to permit_actions :test
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `.to forbid_action[s]` over `.not_to permit_action[s]`.
    RUBY
    expect_correction(<<~RUBY)
      expect(instance).to forbid_actions :test
    RUBY
  end
end
