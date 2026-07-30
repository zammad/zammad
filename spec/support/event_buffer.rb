# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  # Model events of an example must not leak into the next one via the thread-local
  #   EventBuffer, e.g. when an example creates tickets without draining the buffer
  #   through Transaction.execute.
  config.after do
    TransactionDispatcher.reset
  end
end
