class Observer::Ticket::Article::CommunicateSignal::BackgroundJob
  def initialize(id)
    @article_id = id
  end

  def perform
    article = Ticket::Article.find(@article_id)

    # set retry count
    article.preferences['delivery_retry'] ||= 0
    article.preferences['delivery_retry'] += 1

    ticket = Ticket.lookup(id: article.ticket_id)
    Rails.logger.debug { 'SIGNAL BACKGROUND JOB ' }
    Rails.logger.debug { ticket.inspect }
    Rails.logger.debug { article.inspect }
    log_error(article, "Can't find ticket.preferences for Ticket.find(#{article.ticket_id})") if !ticket.preferences
    log_error(article, "Can't find ticket.preferences['sigarillo'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['sigarillo']
    log_error(article, "Can't find ticket.preferences['sigarillo']['chat_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['sigarillo']['chat_id']
    log_error(article, "Can't find ticket.preferences['sigarillo']['bot_id'] for Ticket.find(#{article.ticket_id})") if !ticket.preferences['sigarillo']['bot_id']

    channel = Sigarillo.bot_by_bot_id(ticket.preferences['sigarillo']['bot_id'])
    Rails.logger.debug { "sigarillo got channel for #{channel.inspect}" }

    if !channel
      channel = Channel.lookup(id: ticket.preferences['channel_id'])
    end
    log_error(article, "No such channel for bot #{ticket.preferences['sigarillo']['bot_id']} or channel id #{ticket.preferences['channel_id']}") if !channel
    log_error(article, "Channel.find(#{channel.id}) has no sigarillo api token!") if channel.options[:api_token].blank?

    begin
      result = channel.deliver(
        to:   ticket.preferences[:sigarillo][:chat_id],
        body: article.body,
      )
    rescue => e
      log_error(article, e.message)
      return
    end

    Rails.logger.debug { "send result: #{result}" }

    if result.nil? || result[:error].present?
      log_error(article, 'Delivering sigarillo message failed!')
      return
    end

    article.to = result['result']['recipient']
    article.from = result['result']['source']

    message_id = format('%<source>s@%<timestamp>s', source: result['result']['source'], timestamp: result['result']['timestamp'])
    article.preferences['sigarillo'] = {
      timestamp:  result['result']['timestamp'],
      message_id: message_id,
      from:       result['result']['source'],
      to:         result['result']['recipient'],
    }

    # set delivery status
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now

    article.message_id = "sigarillo.#{message_id}"

    article.save!

    Rails.logger.info "Sent signal message to: '#{article.to}' (from #{article.from})"

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
        body:          "Unable to send signal message: #{message}",
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
