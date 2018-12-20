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

    # check if authentication should be performed
    next if example.metadata.fetch(:authenticated, true).blank?

    # authenticate
    login(
      username: 'master@example.com',
      password: 'test',
    )
  end
end
