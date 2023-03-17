# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  define_method :label_of do |expected|
    expected.gsub('::', " \u203A ".encode('utf-8'))
  end

  matcher :have_selected_option_with_parent do
    match do
      begin
        actual.find('[role="listitem"]', exact_text: label_of(expected), wait: false)
      rescue
        false
      end
    end

    failure_message do
      %(expected #{actual.field_id} to have selected option with parent "#{expected}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have selected option with parent "#{expected}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_selected_option_with_parent, :have_selected_option_with_parent

  matcher :have_selected_options_with_parent do
    match do
      expected.all? do |path|
        begin
          actual.find('[role="listitem"]', exact_text: label_of(path), wait: false)
        rescue
          false
        end
      end
    end

    failure_message do
      %(expected #{actual.field_id} to have selected options with parent "#{expected}")
    end

    failure_message_when_negated do
      %(expected #{actual.field_id} not to have selected options with parent "#{expected}")
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_selected_options_with_parent, :have_selected_options_with_parent
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
