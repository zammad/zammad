# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketOnlineNotificationSeenJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TicketOnlineNotificationSeenJob/23/42"
    "#{self.class.name}/#{arguments[0]}/#{arguments[1]}"
  end

  def perform(ticket_id, user_id)
    user_id ||= 1

    # set all online notifications to seen
    Transaction.execute do
      ticket = Ticket.lookup(id: ticket_id)
      return if ticket.nil?
      return if !OnlineNotification.seen_state?(ticket)

      mention_user_ids = ticket.mentions.map(&:user_id)

      unseen_notifications = OnlineNotification.list_by_object('Ticket', ticket_id)
                                               .where(seen: false)
                                               .where.not(user_id: mention_user_ids)

      return if unseen_notifications.empty?

      unseen_notifications.each { |n| n.update!(seen: true, updated_by_id: user_id) }
    end
  end
end
