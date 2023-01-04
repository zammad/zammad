# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :have_selected_option do
    match do
      begin
        actual.find('[role="listitem"]', exact_text: expected, wait: false)
      rescue
        false
      end
    end

    failure_message do
      %(expected #{actual.field_id} to have selected option "#{expected}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have selected option "#{expected}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_selected_option, :have_selected_option

  matcher :have_selected_options do
    match do
      expected.all? do |label|
        begin
          actual.find('[role="listitem"]', exact_text: label, wait: false)
        rescue
          false
        end
      end
    end

    failure_message do
      %(expected #{actual.field_id} to have selected options #{expected})
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have selected options #{expected})
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_selected_options, :have_selected_options
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
