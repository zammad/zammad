# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Schedules a background job to update the user's ticket seen information on ticket changes.
module Ticket::SetsOnlineNotificationSeen
  extend ActiveSupport::Concern

  included do
    after_save :ticket_set_online_notification_seen
  end

  private

  def ticket_set_online_notification_seen

    # return if we run import mode
    return false if Setting.get('import_mode')

    # set seen only if state has changes
    return false if !saved_changes?
    return false if saved_changes['state_id'].blank?

    # check if existing online notifications for this ticket should be set to seen
    return true if !OnlineNotification.seen_state?(self)

    # Register after_commit callback to enqueue the job after transaction completes.
    ApplicationModel.current_transaction.after_commit do
      TicketOnlineNotificationSeenJob.perform_later(self, updated_by_id)
    end
  end
end
