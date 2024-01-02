# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :have_value do
    match do
      actual.input_element.value == expected
    end

    failure_message do
      %(expected #{actual.field_id} to have value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.value}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.value}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_value, :have_value

  matcher :have_text_value do |*args, **options|
    match do
      actual.input_element.has_text?(*args, **options)
    end

    failure_message do
      %(expected #{actual.field_id} to have text value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.text}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have text value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.text}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_text_value, :have_text_value

  matcher :have_data_value do
    match do
      actual.input_element['data-value'].include? expected
    end

    failure_message do
      %(expected #{actual.field_id} to have data value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element['data-value']}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have data value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element['data-value']}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_data_value, :have_data_value
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
  config.include FormMatchers, type: :system, app: :desktop_view
end
