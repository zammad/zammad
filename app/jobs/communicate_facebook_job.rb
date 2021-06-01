# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CommunicateFacebookJob < ApplicationJob

  retry_on StandardError, attempts: 4, wait: lambda { |executions|
    executions * 120.seconds
  }

  def perform(article_id)
    article = Ticket::Article.find(article_id)

    # set retry count
    article.preferences['delivery_retry'] ||= 0
    article.preferences['delivery_retry'] += 1

    ticket = Ticket.lookup(id: article.ticket_id)
    log_error(article, "Can't find ticket.preferences for Ticket.find(#{article.ticket_id})") if !ticket.preferences
    log_error(article, "Can't find ticket.preferences['channel_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['channel_id']
    channel = Channel.lookup(id: ticket.preferences['channel_id'])
    log_error(article, "Channel.find(#{channel.id}) isn't a twitter channel!") if !channel.options[:adapter].match?(%r{\Afacebook}i)

    # check source object id
    if !ticket.preferences['channel_fb_object_id']
      log_error(article, "fb object id is missing in ticket.preferences['channel_fb_object_id'] for Ticket.find(#{ticket.id})")
    end

    # fill in_reply_to
    if article.in_reply_to.blank?
      article.in_reply_to = ticket.articles.first.message_id
    end

    begin
      facebook = Channel::Driver::Facebook.new
      post     = facebook.send(
        channel.options,
        ticket.preferences[:channel_fb_object_id],
        {
          type:        article.type.name,
          to:          article.to,
          body:        article.body,
          in_reply_to: article.in_reply_to,
        }
      )
    rescue => e
      log_error(article, e.message)
      return
    end

    if !post
      log_error(article, 'Got no post!')
      return
    end

    # fill article with post info
    article.from       = post['from']['name']
    article.message_id = post['id']

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.save!

    Rails.logger.info "Send facebook to: '#{article.to}' (from #{article.from})"

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
        body:          "Unable to send post: #{message}",
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
