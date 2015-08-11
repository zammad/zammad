class Observer::Ticket::OnlineNotificationSeen::BackgroundJob
  def initialize(id)
    @ticket_id = id
  end

  def perform

    # set all online notifications to seen
    OnlineNotification.seen_by_object( 'Ticket', @ticket_id )
  end
end
