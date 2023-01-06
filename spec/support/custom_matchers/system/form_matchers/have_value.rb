# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  matcher :have_html_value do
    match do
      actual.input_element.native.attribute('innerHTML').include? expected
    end

    failure_message do
      %(expected #{actual.field_id} to have HTML value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.native.attribute('innerHTML')}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have HTML value "#{expected}"\n\n#{actual.field_id}: "#{actual.input_element.native.attribute('innerHTML')}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_html_value, :have_html_value
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
