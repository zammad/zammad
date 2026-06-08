# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketSummaryAIStoredResultCleanup < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    AI::StoredResult.cleanup(identifier: 'ticket_summarize')
  end
end
