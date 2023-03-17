# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ZammadSpecSupportModel
  extend RSpec::Matchers::DSL

  matcher :have_validator do
    chain(:on, :attribute)

    match do
      actual
        .validators_on(@attribute)
        .any?(expected)
    end

    failure_message do
      %(expected #{actual.name} to use #{expected.name} to validate value of #{@attribute})
    end
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportModel, type: :model
end
