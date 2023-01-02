# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rspec/retry'

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true
  # The list of exceptions to fail on should be configured in the individual :run_with_retry calls.
end
