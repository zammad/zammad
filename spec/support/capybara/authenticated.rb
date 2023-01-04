# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# This file registers a hook before each system test
# which logs in with/authenticates the admin@example.com account.

# we need to make sure that Capybara is configured/started before
# this hook. Otherwise a login try is performed while the app/puma
# hasn't started yet.
require_relative './driven_by'

RSpec.configure do |config|

  config.before(:each, type: :system) do |example|

    ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = nil
    ENV['FAKE_SELENIUM_LOGIN_PENDING'] = nil

    # there is no way to authenticated in a not set up system
    next if !example.metadata.fetch(:set_up, true)

    authenticated = example.metadata.fetch(:authenticated_as, true)
    credentials = authenticated_as_get_user(authenticated, return_type: :credentials)

    authentication_type = example.metadata.fetch(:authentication_type, :auto)

    next if credentials.nil?

    if authentication_type == :form
      login(**credentials, app: example.metadata[:app])
    else
      ENV['FAKE_SELENIUM_LOGIN_USER_ID'] = User.find_by(email: credentials[:username]).id.to_s

      if example.metadata[:app] != :mobile
        ENV['FAKE_SELENIUM_LOGIN_PENDING'] = 'true'
      end
    end
  end
end
