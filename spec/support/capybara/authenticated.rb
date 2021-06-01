# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This file registers a hook before each system test
# which logs in with/authenticates the master@example.com account.

# we need to make sure that Capybara is configured/started before
# this hook. Otherwise a login try is performed while the app/puma
# hasn't started yet.
require_relative './driven_by'

RSpec.configure do |config|

  config.before(:each, type: :system) do |example|

    # there is no way to authenticated in a not set up system
    next if !example.metadata.fetch(:set_up, true)

    authenticated = example.metadata.fetch(:authenticated_as, true)
    credentials   = authenticated_as_get_user(authenticated, return_type: :credentials)

    login(credentials) if credentials
  end
end
