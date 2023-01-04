# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :have_selected_choice do
    match do
      actual.has_css?('label', exact_text: expected, wait: false) { |element| element['data-is-checked'] == 'true' }
    end

    failure_message do
      %(expected #{actual.field_id} to have selected choice "#{expected}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have selected choice "#{expected}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_selected_choice, :have_selected_choice
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
