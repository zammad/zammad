# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :have_date do
    match do
      actual.input_element.value == datestamp
    end

    def datestamp
      date = expected

      if !expected.is_a?(Date)
        date = Date.parse(expected)
      end

      # TODO: Support locales other than `en`, depending on the language of the current user.
      date.strftime('%m/%d/%Y')
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_date, :have_date

  matcher :have_datetime do
    match do
      actual.input_element.value == timestamp
    end

    def timestamp
      datetime = expected

      if !expected.is_a?(DateTime) && !expected.is_a?(Time)
        datetime = DateTime.parse(expected)
      end

      # TODO: Support locales other than `en`, depending on the language of the current user.
      datetime.strftime('%m/%d/%Y %l:%M %P')
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_datetime, :have_datetime
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
