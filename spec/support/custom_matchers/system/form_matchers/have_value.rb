# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :have_value do
    match do
      actual.input_element.value == expected
    end
  end

  RSpec::Matchers.define_negated_matcher :have_no_value, :have_value
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
