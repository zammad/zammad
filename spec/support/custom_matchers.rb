# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

RSpec::Matchers.define :have_multiple_texts do
  match do
    wait.until do
      expected.all? do |elem|
        actual.has_text? elem, wait: 0
      end
    end
  end

  match_when_negated do
    wait.until do
      expected.all? do |elem|
        actual.has_no_text? elem, wait: 0
      end
    end
  end

  failure_message do
    missing = array_to_display expected.reject { |elem| actual.has_text? elem, wait: 0 }

    "Expected element to have #{expected_texts_display} but #{missing} missing"
  end

  failure_message_when_negated do
    present = array_to_display expected.select { |elem| actual.has_text? elem, wait: 0 }

    "Expected element to have #{expected_texts_display} but #{present} missing"
  end

  def expected_texts_display
    array_to_display expected
  end

  def array_to_display(input)
    input
      .map { |elem| "\"#{elem}\"" }
      .join(', ')
  end
end

RSpec::Matchers.define_negated_matcher :have_no_multiple_texts, :have_multiple_texts
