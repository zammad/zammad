# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Mixin
  module StartFinishLogger
    include ::Mixin::RailsLogger

    def log_start_finish(level, prefix)
      logger.public_send(level, "#{prefix} started.")
      yield
      logger.public_send(level, "#{prefix} finished.")
    end
  end
end
