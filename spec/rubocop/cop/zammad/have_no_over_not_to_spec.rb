# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/have_no_over_not_to'

RSpec.describe RuboCop::Cop::Zammad::HaveNoOverNotTo, type: :rubocop do

  it 'accepts .to have_no' do
    expect_no_offenses("expect(page).to have_no_css('#elem')")
  end

  context 'with .not_to have' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        expect(page).not_to have_css('#elem')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `.to have_no_css` over `.not_to have_css`.
      RUBY

      expect_correction(<<~RUBY)
        expect(page).to have_no_css('#elem')
      RUBY
    end
  end
end
