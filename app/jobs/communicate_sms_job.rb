# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CommunicateSmsJob < ApplicationJob

  retry_on StandardError, attempts: 4, wait: lambda { |executions|
    executions * 120.seconds
  }

  def perform(article_id)
    article = Ticket::Article.find(article_id)

    # set retry count
    article.preferences['delivery_retry'] ||= 0
    article.preferences['delivery_retry'] += 1

    ticket = Ticket.lookup(id: article.ticket_id)
    log_error(article, "Can't find article.preferences for Ticket::Article.find(#{article.id})") if !article.preferences

    # if sender is system, take article channel
    if article.sender.name == 'System'
      log_error(article, "Can't find article.preferences['sms_recipients'] for Ticket::Article.find(#{article.id})") if !article.preferences['sms_recipients']
      log_error(article, "Can't find article.preferences['channel_id'] for Ticket::Article.find(#{article.id})") if !article.preferences['channel_id']
      channel = Channel.lookup(id: article.preferences['channel_id'])
      log_error(article, "No such channel id #{article.preferences['channel_id']}") if !channel

    # if sender is agent, take create channel
    else
      log_error(article, "Can't find ticket.preferences['channel_id'] for Ticket.find(#{ticket.id})") if !ticket.preferences['channel_id']
      channel = Channel.lookup(id: ticket.preferences['channel_id'])
      log_error(article, "No such channel id #{ticket.preferences['channel_id']}") if !channel
    end

    begin
      if article.sender.name == 'System'
        article.preferences['sms_recipients'].each do |recipient|
          channel.deliver(
            recipient: recipient,
            message:   article.body.first(160),
          )
        end
      else
        channel.deliver(
          recipient: article.to,
          message:   article.body.first(160),
        )
      end
    rescue => e
      log_error(article, e.message)
      return
    end

    log_success(article)

    return if article.sender.name == 'Agent'

    log_history(article, ticket, 'sms', article.to)
  end

  # log successful delivery
  def log_success(article)
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now
    article.save!
  end

  def log_error(local_record, message)
    local_record.preferences['delivery_status'] = 'fail'
    local_record.preferences['delivery_status_message'] = message
    local_record.preferences['delivery_status_date'] = Time.zone.now
    local_record.save!
    Rails.logger.error message

    if local_record.preferences['delivery_retry'] >= max_attempts
      Ticket::Article.create(
        ticket_id:     local_record.ticket_id,
        content_type:  'text/plain',
        body:          "#{log_error_prefix}: #{message}",
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

  def log_history(article, ticket, history_type, recipient_list)
    return if recipient_list.blank?

    History.add(
      o_id:                   article.id,
      history_type:           history_type,
      history_object:         'Ticket::Article',
      related_o_id:           ticket.id,
      related_history_object: 'Ticket',
      value_from:             article.subject,
      value_to:               recipient_list,
      created_by_id:          article.created_by_id,
    )
  end

  def log_error_prefix
    'Unable to send sms message'
  end
end
