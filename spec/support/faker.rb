# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.after do
    Faker::UniqueGenerator.clear

    # Reset the locale, so that a spec changing it (instead of using Faker::Base.with_locale)
    #  cannot leak e.g. German umlaut names into later specs of the same process,
    #  which can behave differently (e.g. in database collation sorting).
    Faker::Config.locale = :en
  end
end
