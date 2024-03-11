# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Type::BaseDeliver < Service::Base
  attr_reader :article, :ticket, :channel, :result

  def initialize(article_id:)
    super()

    @article = Ticket::Article.find(article_id)
    @ticket = Ticket.lookup(id: article.ticket_id)

    error!(message: "Can't find ticket.preferences['channel_id'] for Ticket.find(#{ticket.id})") if !ticket.preferences['channel_id']

    @channel = find_channel
    check_channel!
  end

  def execute
    increase_delivery_retry_count

    begin
      @result = channel.deliver(deliver_arguments)
    rescue => e
      raise_and_maybe_retry!(e)
    end

    handle_deliver_result

    provide_article_preferences_delivery_success
    article.save!

    Rails.logger.info "Send #{channel_adapter} message to: '#{article.to}' (from #{article.from})"

    article
  end

  private

  def channel_adapter
    raise NotImplementedError
  end

  def find_channel
    Channel.lookup(id: ticket.preferences['channel_id'])
  end

  def check_channel!
    error!(message: "Channel.find(#{ticket.preferences['channel_id']}) does not exist anymore!") if !channel
    error!(message: "Channel.find(#{channel.id}) isn't a #{channel_adapter} channel!") if channel.options[:adapter] != channel_adapter
  end

  def deliver_arguments
    raise NotImplementedError
  end

  def handle_deliver_result
    raise NotImplementedError
  end

  def provide_article_preferences_delivery_success
    article.preferences['delivery_status_message'] = nil
    article.preferences['delivery_status'] = 'success'
    article.preferences['delivery_status_date'] = Time.zone.now
  end

  def increase_delivery_retry_count
    article.preferences['delivery_retry'] ||= 0
    article.preferences['delivery_retry'] += 1
  end

  def raise_and_maybe_retry!(error)
    message = error.message

    save_article_preference_delivery(
      message:,
      status:  'fail'
    )
    Rails.logger.error message

    if !error.retryable?
      create_delivery_failed_article(message:)

      raise Service::Ticket::Article::Type::PermanentDeliveryError, message
    end

    if article.preferences['delivery_retry'] > 3
      create_delivery_failed_article(message:)
    end

    raise Service::Ticket::Article::Type::TemporaryDeliveryError, message
  end

  def error!(message:)
    save_article_preference_delivery(
      message:,
      status:  'fail'
    )
    Rails.logger.error message

    create_delivery_failed_article(message:)

    raise Service::Ticket::Article::Type::PermanentDeliveryError, message
  end

  def save_article_preference_delivery(message:, status: 'success')
    article.preferences['delivery_status'] = status
    article.preferences['delivery_status_date'] = Time.zone.now
    article.preferences['delivery_status_message'] = message&.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '?')

    article.save!
  end

  def create_delivery_failed_article(message:)
    Ticket::Article.create(
      ticket_id:     ticket.id,
      content_type:  'text/plain',
      body:          "Unable to send #{channel_adapter} message: #{message}",
      internal:      true,
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      preferences:   {
        delivery_article_id_related: article.id,
        delivery_message:            true,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
