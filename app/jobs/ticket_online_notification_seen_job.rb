# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketOnlineNotificationSeenJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TicketOnlineNotificationSeenJob/23/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def perform(ticket_id, user_id)
    user_id = user_id || 1

    # set all online notifications to seen
    Transaction.execute do
      ticket = Ticket.lookup(id: ticket_id)
      OnlineNotification.list_by_object('Ticket', ticket_id).each do |notification|
        next if notification.seen

        seen = ticket.online_notification_seen_state(notification.user_id)
        next if !seen
        next if seen == notification.seen

        notification.seen = true
        notification.updated_by_id = user_id
        notification.save!
      end
    end
  end
end
