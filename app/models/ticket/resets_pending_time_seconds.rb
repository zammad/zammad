# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Ensures pending time is always zero-seconds.
module Ticket::ResetsPendingTimeSeconds
  extend ActiveSupport::Concern

  included do
    before_save :ticket_reset_pending_time_seconds
  end

  private

  def ticket_reset_pending_time_seconds
    return true if pending_time.blank?
    return true if !pending_time_changed?
    return true if pending_time.sec.zero?

    self.pending_time = pending_time.change sec: 0
  end
end
