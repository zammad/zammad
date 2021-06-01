# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|
  config.before(:suite) do
    next if !ENV['RESET_BEFORE_SUITE']

    Rake::Task['zammad:db:reset'].invoke
  end
end
