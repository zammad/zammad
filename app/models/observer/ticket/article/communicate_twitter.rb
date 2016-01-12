# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateTwitter < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return if sender.nil?
    return if sender['name'] == 'Customer'

    # only apply on tweets
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return if type['name'] !~ /\Atwitter/i

    ticket = Ticket.lookup(id: record.ticket_id)
    fail "Can't find ticket.preferences for Ticket.find(#{record.ticket_id})" if !ticket.preferences
    fail "Can't find ticket.preferences['channel_id'] for Ticket.find(#{record.ticket_id})" if !ticket.preferences['channel_id']
    channel = Channel.lookup(id: ticket.preferences['channel_id'])
    fail "Channel.find(#{channel.id}) isn't a twitter channel!" if channel.options[:adapter] !~ /\Atwitter/i
    tweet = channel.deliver(
      type:        type['name'],
      to:          record.to,
      body:        record.body,
      in_reply_to: record.in_reply_to
    )

    # fill article with tweet info

    # direct message
    if tweet.class == Twitter::DirectMessage
      record.from = "@#{tweet.sender.screen_name}"
      record.to = "@#{tweet.recipient.screen_name}"

    # regular tweet
    elsif tweet.class == Twitter::Tweet
      record.from = "@#{tweet.user.screen_name}"
      if tweet.user_mentions
        to = ''
        twitter_mention_ids = []
        tweet.user_mentions.each {|user|
          if to != ''
            to += ' '
          end
          to += "@#{user.screen_name}"
          twitter_mention_ids.push user.id
        }
        record.to = to
        record.preferences[:twitter_mention_ids] = twitter_mention_ids
      end
    else
      fail "Unknown tweet type '#{tweet.class}'"
    end

    record.message_id = tweet.id
    record.save
  end

end
