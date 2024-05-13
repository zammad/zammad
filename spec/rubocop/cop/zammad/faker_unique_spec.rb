# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/faker_unique'

RSpec.describe RuboCop::Cop::Zammad::FakerUnique, :aggregate_failures, type: :rubocop do

  it 'accepts unique calls' do
    expect_no_offenses('Faker::Number.unique.number')
    expect_no_offenses('Faker::Name.unique.first_name')
    expect_no_offenses('Faker::Date.unique.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01")).to_datetime')
    expect_no_offenses('Faker::Time.unique.between(from: Date.parse("2022-01-01"), to: Date.parse("2024-01-01")).to_datetime')
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

  it 'rejects other calls for Faker::Date' do
    expect_offense(<<~RUBY)
      Faker::Date.between(from: Date.parse('2022-01-01'), to: Date.parse('2024-01-01')).to_datetime
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Always use Faker::*::.unique to prevent race conditions in tests.
    RUBY
    expect_correction(<<~RUBY)
      Faker::Date.unique.between(from: Date.parse('2022-01-01'), to: Date.parse('2024-01-01')).to_datetime
    RUBY
  end

  it 'rejects other calls for Faker::Time' do
    expect_offense(<<~RUBY)
      Faker::Time.between(from: Date.parse('2022-01-01'), to: Date.parse('2024-01-01')).to_datetime
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Always use Faker::*::.unique to prevent race conditions in tests.
    RUBY
    expect_correction(<<~RUBY)
      Faker::Time.unique.between(from: Date.parse('2022-01-01'), to: Date.parse('2024-01-01')).to_datetime
    RUBY
  end
end
