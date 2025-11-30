# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      channel = TelegramHelper.bot_by_bot_id(ticket.preferences['telegram']['bid'])
    end
    if !channel
      channel = Channel.lookup(id: ticket.preferences['channel_id'])
    end
    log_error(article, "No such channel for bot #{ticket.preferences['bid']} or channel id #{ticket.preferences['channel_id']}") if !channel
    # log_error(article, "Channel.find(#{channel.id}) isn't a telegram channel!") if channel.options[:adapter] !~ /\Atelegram/i
    log_error(article, "Channel.find(#{channel.id}) has not telegram api token!") if channel.options[:api_token].blank?

    result = nil
    begin
      Telegram::Bot::Client.run(channel.options[:api_token]) do |bot|
        chat_id = ticket.preferences[:telegram][:chat_id]

        # Prepare message content and options
        message_text = article.body
        message_options = { chat_id: chat_id, text: message_text }

        # Apply template if specified
        if article.preferences['telegram_template_id']
          template = TelegramTemplate.find_by(id: article.preferences['telegram_template_id'])
          if template && template.active
            message_text = template.render(article: article)
            message_options[:text] = message_text
            message_options[:parse_mode] = template.parse_mode if template.parse_mode.present?

            # Add inline keyboard if defined
            keyboard = template.build_inline_keyboard
            message_options[:reply_markup] = keyboard if keyboard
          end
        end

        # Check for inline keyboard in article preferences (for ad-hoc keyboards)
        if article.preferences['telegram_keyboard'] && article.preferences['telegram_keyboard'].present?
          message_options[:reply_markup] = {
            inline_keyboard: article.preferences['telegram_keyboard']
          }
        end

        # Check for parse mode in article preferences (for ad-hoc formatting)
        if article.preferences['telegram_parse_mode']
          message_options[:parse_mode] = article.preferences['telegram_parse_mode']
        end

        # Send message
        result = bot.api.sendMessage(message_options)

        # Handle broadcast to multiple chat IDs
        if article.preferences['telegram_broadcast_chat_ids'].present?
          article.preferences['telegram_broadcast_chat_ids'].each do |broadcast_chat_id|
            next if broadcast_chat_id == chat_id # Skip original chat

            broadcast_options = message_options.dup
            broadcast_options[:chat_id] = broadcast_chat_id
            bot.api.sendMessage(broadcast_options)
          rescue => e
            Rails.logger.warn "Failed to broadcast to chat_id #{broadcast_chat_id}: #{e.message}"
          end
        end

        # Send attachments
        article.attachments.each do |file|
          parts = file.filename.split(%r{^(.*)(\..+?)$})
          t = Tempfile.new([parts[1], parts[2]])
          t.binmode
          t.write(file.content)
          t.rewind

          upload = Faraday::UploadIO.new(
            t.path,
            file.preferences['Content-Type'],
            file.filename
          )

          bot.api.sendDocument(chat_id: chat_id, document: upload)
        end
      end
    rescue => e
      log_error(article, e.message)
      return
    end

    Rails.logger.debug { "result info: #{result}" }

    # only private, group messages. channel messages do not have from key
    if result.from && result.chat
      # fill article with message info
      article.from = "@#{result.from.username}"
      article.to = "@#{result.chat.username}"

      article.preferences['telegram'] = {
        date:       result.date,
        from_id:    result.from.id,
        chat_id:    result.chat.id,
        message_id: result.message_id
      }
    else
      # fill article with message info (telegram channel)
      article.from = "@#{me['username']}"
      article.to = "#{result.chat.title} Channel"

      article.preferences['telegram'] = {
        date:       result.date,
        from_id:    me['id'],
        chat_id:    result.chat.id,
        message_id: result.message_id
      }
    end

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.message_id = "telegram.#{result.message_id}.#{result.chat.id}"

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
