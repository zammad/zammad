# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Adds a background job to update the user's ticket counter on ticket changes.
#
# Uses after_save to check for relevant changes and manually registers an after_commit
# callback to enqueue the job. This approach works correctly even when multiple saves
# happen in the same transaction (e.g., ticket.save! followed by article.save! which
# touches the ticket), because we check changes at each save and capture needed values
# in a closure.
module Ticket::EnqueuesUserTicketCounterJob
  extend ActiveSupport::Concern

  included do
    after_save :enqueue_user_ticket_counter_job_after_commit
  end

  private

  def enqueue_user_ticket_counter_job_after_commit
    # return if we run import mode
    return true if Setting.get('import_mode')
    return true if BulkImportInfo.enabled?
    return true if !customer_id

    # Only proceed when state_id, customer_id or organization_id changes.
    return true if !saved_change_to_state_id? && !saved_change_to_customer_id? && !saved_change_to_organization_id?

    # Register after_commit callback to enqueue the job after transaction completes
    ApplicationModel.current_transaction.after_commit do
      TicketUserTicketCounterJob.perform_later(
        customer_id,
        organization_id,
        UserInfo.current_user_id || updated_by_id,
      )
    end

    true
  end
end
