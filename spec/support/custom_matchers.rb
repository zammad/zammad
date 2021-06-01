# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# taken from https://makandracards.com/makandra/1080-rspec-matcher-to-check-if-an-activerecord-exists-in-the-database
RSpec::Matchers.define :exist_in_database do

  match do |actual|
    actual.class.exists?(actual.id)
  end
end
