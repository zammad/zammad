# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketResponseTime

  def self.log(object, o_id)
    return if object != 'Ticket'

    ticket = Ticket.lookup(id: o_id)

    article_created_by_id = 3

    # check if response was sent by owner
    return if ticket.owner_id != 1 && ticket.owner_id != article_created_by_id

    # return if customer send at least
    return if ticket.last_contact_customer > ticket.last_contact_agent

    # TODO: only business hours
    response_time_taken = ticket.last_contact_agent - ticket.last_contact_customer

    (response_time_taken / 60).round
  end

  def self.generate(user)
    items = StatsStore.where('created_at > ? AND created_at < ?', Time.zone.now - 7.days, Time.zone.now).where(key: 'ticket:response_time')
    count_total = items.count
    total = 0
    count_own = 0
    own = 0
    items.each {|_item|
      ticket = Ticket.lookup(id: data[:ticket_id])
      if ticket.owner_id == user.id
        count_own += 1
        own += data[:time]
      end
      total += data[:time]
    }
    if total != 0
      own = (own / count_own).round
    end
    {
      used_for_average: 0,
      average_per_agent: '-',
      own: own,
      total: total,
    }
  end

end
