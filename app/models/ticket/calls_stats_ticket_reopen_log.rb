# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Adds new and updated tickets to the reopen log processing.
module Ticket::CallsStatsTicketReopenLog
  extend ActiveSupport::Concern

  included do
    after_commit :ticket_call_stats_ticket_reopen_log
  end

  private

  def ticket_call_stats_ticket_reopen_log

    # return if we run import mode
    return if Setting.get('import_mode')

    Stats::TicketReopen.log('Ticket', id, previous_changes, updated_by_id)
  end
end
