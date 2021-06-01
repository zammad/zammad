# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketWaitingTime

  def self.generate(user)

    # get users groups
    group_ids = user.group_ids_access('full')

    own_waiting = []
    all_waiting = []
    Ticket.where('group_id IN (?) AND updated_at > ?', group_ids.sort, Time.zone.today).limit(20_000).pluck(:id, :owner_id).each do |ticket|
      all_waiting.push ticket[0]
      if ticket[1] == user.id
        own_waiting.push ticket[0]
      end
    end

    handling_time = calculate_average(own_waiting, Time.zone.today)
    if handling_time.positive?
      handling_time = (handling_time / 60).round
    end
    average_per_agent = calculate_average(all_waiting, Time.zone.today)
    if average_per_agent.positive?
      average_per_agent = (average_per_agent / 60).round
    end

    percent = 0
    state   = if handling_time <= 60
                percent = handling_time.to_f / 60
                'supergood'
              elsif handling_time <= 60 * 4
                percent = (handling_time.to_f - 60) / (60 * 3)
                'good'
              elsif handling_time <= 60 * 8
                percent = (handling_time.to_f - 60 * 4) / (60 * 4)
                'ok'
              else
                percent = 1.00
                'bad'
              end

    {
      handling_time:     handling_time,
      average_per_agent: average_per_agent,
      state:             state,
      percent:           percent,
    }
  end

  def self.average_state(result, _user_id)
    result
  end

  def self.calculate_average(ticket_ids, start_time)
    average_time   = 0
    count_articles = 0
    last_ticket_id = nil
    count_time     = nil

    Ticket::Article.joins(:type).joins(:sender).where('ticket_articles.ticket_id IN (?) AND ticket_articles.created_at > ? AND ticket_articles.internal = ? AND ticket_article_types.communication = ?', ticket_ids, start_time, false, true).order(:ticket_id, :created_at).pluck(:created_at, :sender_id, :ticket_id, :id).each do |article|
      if last_ticket_id != article[2]
        last_ticket_id = article[2]
        count_time = 0
      end
      sender = Ticket::Article::Sender.lookup(id: article[1])
      if sender.name == 'Customer'
        count_time = article[0].to_i
      elsif count_time.positive?
        average_time   += article[0].to_i - count_time
        count_articles += 1
        count_time      = 0
      end
    end

    if count_articles.positive?
      average_time = average_time / count_articles
    end

    average_time
  end
end
