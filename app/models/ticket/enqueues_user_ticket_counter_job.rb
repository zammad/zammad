# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Adds a background job to update the user's ticket counter on ticket changes.
module Ticket::EnqueuesUserTicketCounterJob
  extend ActiveSupport::Concern

  included do
    after_commit :enqueue_user_ticket_counter_job
  end

  private

  def enqueue_user_ticket_counter_job
    # return if we run import mode
    return true if Setting.get('import_mode')

    return true if BulkImportInfo.enabled?

    return true if destroyed?

    return true if !customer_id

    return true if previous_changes.blank?

    # send background job
    TicketUserTicketCounterJob.perform_later(
      customer_id,
      UserInfo.current_user_id || updated_by_id,
    )
  end

end
