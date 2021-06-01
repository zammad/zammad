# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module TicketStats
  extend ActiveSupport::Concern

  private

  def ticket_ids_and_assets(condition, current_user, limit, assets)
    tickets = Ticket.search(
      limit:        limit,
      condition:    condition,
      current_user: current_user,
      sort_by:      'created_at',
      order_by:     'desc',
    )
    assets_of_tickets(tickets, assets)
  end

  def ticket_stats_last_year(condition, access_condition)
    volume_by_year = []
    now            = Time.zone.now

    (0..11).each do |month_back|
      date_to_check = now - month_back.month
      date_start = "#{date_to_check.year}-#{date_to_check.month}-01 00:00:00"
      date_end   = "#{date_to_check.year}-#{date_to_check.month}-#{date_to_check.end_of_month.day} 00:00:00"

      # created
      created = Ticket.where('created_at > ? AND created_at < ?', date_start, date_end)
                      .where(access_condition)
                      .where(condition)
                      .count

      # closed
      closed = Ticket.where('close_at > ? AND close_at < ?', date_start, date_end)
                     .where(access_condition)
                     .where(condition)
                     .count

      data = {
        month:   date_to_check.month,
        year:    date_to_check.year,
        text:    Date::MONTHNAMES[date_to_check.month],
        created: created,
        closed:  closed,
      }
      volume_by_year.push data
    end
    volume_by_year
  end

  def assets_of_tickets(tickets, assets)
    ticket_ids = []
    tickets.each do |ticket|
      ticket_ids.push ticket.id
      assets = ticket.assets(assets)
    end
    ticket_ids
  end

end
