class Observer::Transaction

  def self.commit(params = {})

    # execute ticket transactions
    Observer::Ticket::Notification.transaction(params)

  end

end
