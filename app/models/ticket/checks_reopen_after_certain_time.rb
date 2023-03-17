# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Adds new and updated tickets to the reopen log processing.
module Ticket::ChecksReopenAfterCertainTime
  extend ActiveSupport::Concern

  included do
    def reopen_after_certain_time?
      # No reopen time is configured.
      return false if !reopen_time_in_days_configured?

      # Ticket is not closed.
      return false if !close_time

      # We missed the possible time frame to reopen, sorry.
      return false if !reopen_in_configured_time?

      true
    end

    private

    def reopen_time_in_days_configured?
      return false if group.reopen_time_in_days.blank?
      return false if !group.reopen_time_in_days.positive?

      true
    end

    def close_time
      last_close_at || close_at
    end

    def reopen_in_configured_time?
      ((Time.zone.now - close_time).to_i / (24 * 60 * 60)) < group.reopen_time_in_days
    end
  end
end
