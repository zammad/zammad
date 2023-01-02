# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  extend RSpec::Matchers::DSL

  matcher :be_toggled_on do
    match do
      actual.input_element.checked?
    end
  end

  RSpec::Matchers.define_negated_matcher :be_toggled_off, :be_toggled_on
end

RSpec.configure do |config|
  config.include FormMatchers, type: :system, app: :mobile
end
