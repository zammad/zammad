# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# taken from https://makandracards.com/makandra/1080-rspec-matcher-to-check-if-an-activerecord-exists-in-the-database
RSpec::Matchers.define :exist_in_database do

  match do |actual|
    actual.class.exists?(actual.id)
  end
end

RSpec::Matchers.define :have_computed_style do

  match do
    actual_value == expected_value
  end

  failure_message do
    "Expected element to have CSS property #{expected_key} with value #{expected_value}. But it was #{actual_value}."
  end

  def expected_key
    expected[0]
  end

  def expected_value
    expected[1]
  end

  def actual_value
    actual.evaluate_script "getComputedStyle(this).#{expected_key}"
  end
end
