# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CommunicateTwitterJob < ApplicationJob

  retry_on StandardError, attempts: 4, wait: lambda { |executions|
    executions * 120.seconds
  }

  def perform(article_id)
    article = Ticket::Article.find(article_id)

    # set retry count
    article.preferences['delivery_retry'] ||= 0
    article.preferences['delivery_retry'] += 1

    ticket = Ticket.lookup(id: article.ticket_id)
    log_error(article, "Can't find ticket.preferences['channel_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['channel_id']
    channel = Channel.lookup(id: ticket.preferences['channel_id'])

    # search for same channel channel_screen_name, in case the channel got re-added
    if !channel
      Channel.where(area: 'Twitter::Account', active: true).each do |local_channel|
        next if ticket.preferences[:channel_screen_name].blank?
        next if !local_channel.options
        next if local_channel.options[:user].blank?
        next if local_channel.options[:user][:screen_name].blank?
        next if local_channel.options[:user][:screen_name] != ticket.preferences[:channel_screen_name]

        channel = local_channel
        break
      end
    end

    log_error(article, "No such channel id #{ticket.preferences['channel_id']}") if !channel
    log_error(article, "Channel.find(#{channel.id}) isn't a twitter channel!") if !channel.options[:adapter].try(:match?, %r{\Atwitter}i)

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
    if tweet.is_a?(Hash)
      tweet_type = 'DirectMessage'
      article.message_id = tweet[:event][:id].to_s
      if tweet[:event] && tweet[:event][:type] == 'message_create'
        #article.from = "@#{tweet.sender.screen_name}"
        #article.to = "@#{tweet.recipient.screen_name}"

        article.preferences['twitter'] = {
          recipient_id: tweet[:event][:message_create][:target][:recipient_id],
          sender_id:    tweet[:event][:message_create][:sender_id],
        }

        article.preferences['links'] = [
          {
            url:    TwitterSync::DM_URL_TEMPLATE % article.preferences[:twitter].slice(:recipient_id, :sender_id).values.map(&:to_i).sort.join('-'),
            target: '_blank',
            name:   'on Twitter',
          },
        ]
      end

    # regular tweet
    elsif tweet.instance_of?(Twitter::Tweet)
      tweet_type = 'Tweet'
      tweet_id = tweet.id.to_s
      article.from = "@#{tweet.user.screen_name}"
      if tweet.user_mentions
        to = ''
        mention_ids = []
        tweet.user_mentions.each do |user|
          if to != ''
            to += ' '
          end
          to += "@#{user.screen_name}"
          mention_ids.push user.id
        end
        article.to = to
        article.preferences['twitter'] = TwitterSync.preferences_cleanup(
          mention_ids:         mention_ids,
          geo:                 tweet.geo,
          retweeted:           tweet.retweeted?,
          possibly_sensitive:  tweet.possibly_sensitive?,
          in_reply_to_user_id: tweet.in_reply_to_user_id,
          place:               tweet.place,
          retweet_count:       tweet.retweet_count,
          source:              tweet.source,
          favorited:           tweet.favorited?,
          truncated:           tweet.truncated?,
          created_at:          tweet.created_at,
        )

        article.message_id = tweet_id
        article.preferences['links'] = [
          {
            url:    TwitterSync::STATUS_URL_TEMPLATE % tweet.id,
            target: '_blank',
            name:   'on Twitter',
          },
        ]
      end
    else
      raise "Unknown tweet type '#{tweet.class}'"
    end

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.save!

    Rails.logger.info "Send twitter (#{tweet_type}) to: '#{article.to}' (from #{article.from})"

    article
  end

  def log_error(local_record, message)
    local_record.preferences['delivery_status'] = 'fail'
    local_record.preferences['delivery_status_message'] = message.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '?')
    local_record.preferences['delivery_status_date'] = Time.zone.now
    local_record.save
    Rails.logger.error message

    if local_record.preferences['delivery_retry'] > 3
      Ticket::Article.create(
        ticket_id:     local_record.ticket_id,
        content_type:  'text/plain',
        body:          "Unable to send tweet: #{message}",
        internal:      true,
        sender:        Ticket::Article::Sender.find_by(name: 'System'),
        type:          Ticket::Article::Type.find_by(name: 'note'),
        preferences:   {
          delivery_article_id_related: local_record.id,
          delivery_message:            true,
        },
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    raise message
  end
end
