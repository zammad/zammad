# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Status
  include Mixin::RequiredSubPaths

  attr_reader :data, :channel, :ticket, :related_article

  def initialize(data:, channel:)
    @data = data
    @channel = channel
  end

  def process
    @related_article = find_related_article
    raise Whatsapp::Webhook::Payload::ProcessableError, __('No related article found to process the status message on.') if @related_article.nil?

    @ticket = @related_article.ticket
    return if ticket_done?

    create_article
    update_related_article
    update_ticket
  end

  private

  def ticket_done?
    state_ids = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    state_ids.include?(@ticket.state_id)
  end

  def body
    raise NotImplementedError
  end

  def status
    @status ||= @data[:entry]
      .first[:changes]
      .first[:value][:statuses]
      .first
  end

  def find_related_article
    Ticket::Article.where(message_id: status[:id])&.first
  end

  def update_related_article?
    true
  end

  def article_timestamp_key
    raise NotImplementedError
  end

  def update_related_article_attributes
    preferences = @related_article.preferences
    preferences[:whatsapp][article_timestamp_key] = status[:timestamp]

    { preferences: }
  end

  def update_related_article
    return if !update_related_article? || update_related_article_attributes.blank?

    UserInfo.with_user_id(@related_article.updated_by_id) do
      @related_article.update!(update_related_article_attributes)
    end
  end

  def create_article?
    false
  end

  def create_article
    return if !create_article?

    Ticket::Article.create!(
      ticket_id:     @ticket.id,
      type_id:       Ticket::Article::Type.lookup(name: 'note').id,
      sender_id:     Ticket::Article::Sender.lookup(name: 'System').id,
      from:          "#{@channel.options[:name]} (#{@channel.options[:phone_number]})",
      internal:      true,
      body:          "Unable to handle WhatsApp message: #{body}",
      content_type:  'text/plain',
      preferences:   {
        delivery_article_id_related: @related_article.id,
        delivery_message:            true,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def update_ticket?
    false
  end

  def update_ticket_attributes
    raise NotImplementedError
  end

  def update_ticket
    return if !update_ticket? || update_ticket_attributes.blank?

    UserInfo.with_user_id(@ticket.updated_by_id) do
      @ticket.update!(update_ticket_attributes)
    end
  end
end
