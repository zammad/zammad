# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Ensures pending time is always zero-seconds.
module Ticket::ResetsPendingTimeSeconds
  extend ActiveSupport::Concern

  included do
    before_create :ticket_reset_pending_time_seconds
    before_update :ticket_reset_pending_time_seconds
  end

  private

  def ticket_reset_pending_time_seconds
    return true if pending_time.blank?
    return true if !pending_time_changed?
    return true if pending_time.sec.zero?

    self.pending_time = pending_time.change sec: 0
  end
end
