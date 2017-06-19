# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Stats::TicketChannelDistribution

  def self.generate(user)

    # which time range?
    time_range = 7.days

    # get users groups
    group_ids = user.group_ids_access('full')

    # get channels
    channels = [
      {
        sender: 'email',
        icon: 'email',
      },
      {
        sender: 'phone',
        icon: 'phone',
      },
      {
        sender: 'twitter',
        icon: 'twitter',
      },
      {
        sender: 'facebook',
        icon: 'facebook',
      },
    ]

    # calcualte
    result = {}
    total_in = 0
    total_out = 0
    channels.each { |channel|
      result[channel[:sender].to_sym] = {
        icon: channel[:icon]
      }
      type_ids = []
      Ticket::Article::Type.all.each { |type|
        next if type.name !~ /^#{channel[:sender]}/i
        type_ids.push type.id
      }

      sender = Ticket::Article::Sender.lookup( name: 'Customer' )
      count = Ticket.where(group_id: group_ids).joins(:articles).where(
        ticket_articles: { sender_id: sender, type_id: type_ids }
      ).where(
        'ticket_articles.created_at > ?', Time.zone.now - time_range
      ).count
      result[channel[:sender].to_sym][:inbound] = count
      total_in += count

      sender = Ticket::Article::Sender.lookup( name: 'Agent' )
      count = Ticket.where(group_id: group_ids).joins(:articles).where(
        ticket_articles: { sender_id: sender, type_id: type_ids }
      ).where(
        'ticket_articles.created_at > ?', Time.zone.now - time_range
      ).count
      result[channel[:sender].to_sym][:outbound] = count
      total_out += count
    }

    # append in percent
    channels.each { |channel|
      count = result[channel[:sender].to_sym][:inbound]
      #puts "#{channel.inspect}:in/#{result.inspect}:#{count}"
      in_process_precent = if count.zero?
                             0
                           else
                             (count * 1000) / ((total_in * 1000) / 100)
                           end
      result[channel[:sender].to_sym][:inbound_in_percent] = in_process_precent

      count = result[channel[:sender].to_sym][:outbound]
      out_process_precent = if count.zero?
                              0
                            else
                              (count * 1000) / ((total_out * 1000) / 100)
                            end
      result[channel[:sender].to_sym][:outbound_in_percent] = out_process_precent
    }

    { channels: result }
  end

  def self.average_state(result, _user_id)
    result
  end

end
