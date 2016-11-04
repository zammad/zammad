class Observer::Ticket::Article::CommunicateTwitter::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    article = Ticket::Article.find(@article_id)

    # set retry count
    if !article.preferences['delivery_retry']
      article.preferences['delivery_retry'] = 0
    end
    article.preferences['delivery_retry'] += 1

    ticket = Ticket.lookup(id: article.ticket_id)
    log_error(article, "Can't find ticket.preferences for Ticket.find(#{article.ticket_id})") if !ticket.preferences
    log_error(article, "Can't find ticket.preferences['channel_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['channel_id']
    channel = Channel.lookup(id: ticket.preferences['channel_id'])
    log_error(article, "No such channel id #{ticket.preferences['channel_id']}") if !channel
    log_error(article, "Channel.find(#{channel.id}) isn't a twitter channel!") if channel.options[:adapter] !~ /\Atwitter/i

    begin
      tweet = channel.deliver(
        type:        article.type.name,
        to:          article.to,
        body:        article.body,
        in_reply_to: article.in_reply_to
      )
    rescue => e
      log_error(article, e.message)
      return
    end
    if !tweet
      log_error(article, 'Got no tweet!')
      return
    end

    # fill article with tweet info

    # direct message
    if tweet.class == Twitter::DirectMessage
      article.from = "@#{tweet.sender.screen_name}"
      article.to = "@#{tweet.recipient.screen_name}"

      article.preferences['twitter'] = {
        created_at: tweet.created_at,
        recipient_id: tweet.recipient.id,
        recipient_screen_name: tweet.recipient.screen_name,
        sender_id: tweet.sender.id,
        sender_screen_name: tweet.sender.screen_name,
      }

    # regular tweet
    elsif tweet.class == Twitter::Tweet
      article.from = "@#{tweet.user.screen_name}"
      if tweet.user_mentions
        to = ''
        mention_ids = []
        tweet.user_mentions.each { |user|
          if to != ''
            to += ' '
          end
          to += "@#{user.screen_name}"
          mention_ids.push user.id
        }
        article.to = to
        article.preferences['twitter'] = {
          mention_ids: mention_ids,
          geo: tweet.geo,
          retweeted: tweet.retweeted?,
          possibly_sensitive: tweet.possibly_sensitive?,
          in_reply_to_user_id: tweet.in_reply_to_user_id,
          place: tweet.place,
          retweet_count: tweet.retweet_count,
          source: tweet.source,
          favorited: tweet.favorited?,
          truncated: tweet.truncated?,
          created_at: tweet.created_at,
        }
      end
    else
      raise "Unknown tweet type '#{tweet.class}'"
    end

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.message_id = tweet.id.to_s
    article.preferences['links'] = [
      {
        url: "https://twitter.com/statuses/#{tweet.id}",
        target: '_blank',
        name: 'on Twitter',
      },
    ]

    article.save!

    Rails.logger.info "Send twitter (#{tweet.class}) to: '#{article.to}' (from #{article.from})"

    article
  end

  def log_error(local_record, message)
    local_record.preferences['delivery_status'] = 'fail'
    local_record.preferences['delivery_status_message'] = message
    local_record.preferences['delivery_status_date'] = Time.zone.now
    local_record.save
    Rails.logger.error message

    if local_record.preferences['delivery_retry'] > 3
      Ticket::Article.create(
        ticket_id: local_record.ticket_id,
        content_type: 'text/plain',
        body: "Unable to send tweet: #{message}",
        internal: true,
        sender: Ticket::Article::Sender.find_by(name: 'System'),
        type: Ticket::Article::Type.find_by(name: 'note'),
        preferences: {
          delivery_article_id_related: local_record.id,
          delivery_message: true,
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    raise message
  end

  def max_attempts
    4
  end

  def reschedule_at(current_time, attempts)
    if Rails.env.production?
      return current_time + attempts * 120.seconds
    end
    current_time + 5.seconds
  end
end
