# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/faker_unique'

RSpec.describe RuboCop::Cop::Zammad::FakerUnique, :aggregate_failures, type: :rubocop do

  it 'accepts unique calls' do
    expect_no_offenses('Faker::Number.unique.number')
    expect_no_offenses('Faker::Name.unique.first_name')
  end

  it 'rejects other calls for Faker::Number' do
    expect_offense(<<~RUBY)
      Faker::Number.number(digits: 6).to_s
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Always use Faker::*::.unique to prevent race conditions in tests.
    RUBY
    expect_correction(<<~RUBY)
      Faker::Number.unique.number(digits: 6).to_s
    RUBY
  end

  it 'rejects other calls for Faker::Name' do
    expect_offense(<<~RUBY)
      Faker::Name.first_name
      ^^^^^^^^^^^^^^^^^^^^^^ Always use Faker::*::.unique to prevent race conditions in tests.
    RUBY
    expect_correction(<<~RUBY)
      Faker::Name.unique.first_name
    RUBY
  end
end
