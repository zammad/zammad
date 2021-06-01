# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CommunicateTelegramJob < ApplicationJob

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
    log_error(article, "Can't find ticket.preferences['telegram'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['telegram']
    log_error(article, "Can't find ticket.preferences['telegram']['chat_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['telegram']['chat_id']
    if ticket.preferences['telegram'] && ticket.preferences['telegram']['bid']
      channel = Telegram.bot_by_bot_id(ticket.preferences['telegram']['bid'])
    end
    if !channel
      channel = Channel.lookup(id: ticket.preferences['channel_id'])
    end
    log_error(article, "No such channel for bot #{ticket.preferences['bid']} or channel id #{ticket.preferences['channel_id']}") if !channel
    #log_error(article, "Channel.find(#{channel.id}) isn't a telegram channel!") if channel.options[:adapter] !~ /\Atelegram/i
    log_error(article, "Channel.find(#{channel.id}) has not telegram api token!") if channel.options[:api_token].blank?

    begin
      api = TelegramAPI.new(channel.options[:api_token])
      chat_id = ticket.preferences[:telegram][:chat_id]
      result = api.sendMessage(chat_id, article.body)
      me = api.getMe()
      article.attachments.each do |file|
        parts = file.filename.split(%r{^(.*)(\..+?)$})
        t = Tempfile.new([parts[1], parts[2]])
        t.binmode
        t.write(file.content)
        t.rewind
        api.sendDocument(chat_id, t.path.to_s)
      end
    rescue => e
      log_error(article, e.message)
      return
    end

    Rails.logger.debug { "result info: #{result}" }

    # only private, group messages. channel messages do not have from key
    if result['from'] && result['chat']
      # fill article with message info
      article.from = "@#{result['from']['username']}"
      article.to = "@#{result['chat']['username']}"

      article.preferences['telegram'] = {
        date:       result['date'],
        from_id:    result['from']['id'],
        chat_id:    result['chat']['id'],
        message_id: result['message_id']
      }
    else
      # fill article with message info (telegram channel)
      article.from = "@#{me['username']}"
      article.to = "#{result['chat']['title']} Channel"

      article.preferences['telegram'] = {
        date:       result['date'],
        from_id:    me['id'],
        chat_id:    result['chat']['id'],
        message_id: result['message_id']
      }
    end

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.message_id = "telegram.#{result['message_id']}.#{result['chat']['id']}"

    article.save!

    Rails.logger.info "Send telegram message to: '#{article.to}' (from #{article.from})"

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
        body:          "Unable to send telegram message: #{message}",
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
