class Observer::Ticket::OnlineNotificationSeen::BackgroundJob
  def initialize(id)
    @ticket_id = id
  end

  def perform

    # set all online notifications to seen
    ActiveRecord::Base.transaction do
      ticket = Ticket.lookup(id: @ticket_id)
      OnlineNotification.list_by_object('Ticket', @ticket_id).each {|notification|
        next if notification.seen
        seen = ticket.online_notification_seen_state(notification.user_id)
        next if !seen
        next if seen == notification.seen
        notification.seen = true
        notification.save
      }
    end
  end
end
