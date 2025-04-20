# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Stats::TicketCreatedToday

  def self.generate

    # get count of tickets created today
    tickets_today = Ticket.where(created_at: Time.zone.today.all_day).count

    # Calculate the average amount of tickets created daily for the last 365 days
    now = DateTime.now
    last_year = now - 365.days
    total_yearly_tickets = Ticket.where(created_at: last_year..now).count
    daily_average = (total_yearly_tickets / 365).round

    {
      tickets_today:     tickets_today,
      daily_average:     daily_average,
    }
  end

  def self.average_state(result, _user_id)
    result
  end

end
