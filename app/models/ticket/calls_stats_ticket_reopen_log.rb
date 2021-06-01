# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'stats/ticket_reopen'

# Adds new and updated tickets to the reopen log processing.
module Ticket::CallsStatsTicketReopenLog
  extend ActiveSupport::Concern

  included do
    before_create :ticket_call_stats_ticket_reopen_log
    before_update :ticket_call_stats_ticket_reopen_log
  end

  private

  def ticket_call_stats_ticket_reopen_log

    # return if we run import mode
    return if Setting.get('import_mode')

    Stats::TicketReopen.log('Ticket', id, saved_changes, updated_by_id)
  end
end
