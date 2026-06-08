# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Adds new and updated tickets to the reopen log processing.
module Ticket::CallsStatsTicketReopenLog
  extend ActiveSupport::Concern

  included do
    after_save :ticket_call_stats_ticket_reopen_log
  end

  private

  def ticket_call_stats_ticket_reopen_log
    # return if we run import mode
    return if Setting.get('import_mode')

    return if close_at.blank?
    return if owner_id == 1

    return if !saved_change_to_state_id?
    return if !saved_change_to_state_id[0]

    # Capture changes before commit.
    saved_changes_to_log = saved_changes.dup

    # Register after_commit callback to execute after transaction completes
    ApplicationModel.current_transaction.after_commit do
      Stats::TicketReopen.log('Ticket', id, saved_changes_to_log, updated_by_id)
    end
  end
end
