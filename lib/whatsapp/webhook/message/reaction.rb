# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Reaction < Whatsapp::Webhook::Message

  attr_reader :related_article

  def type
    :reaction
  end

  def process
    @related_article = find_related_article
    raise Whatsapp::Webhook::Payload::ProcessableError, __('No related article found to process the reaction message on.') if @related_article.nil?

    @ticket = @related_article.ticket
    return if ticket_done?

    @user = create_or_update_user
    UserInfo.current_user_id = @user.id

    history_type = determine_history_type
    update_related_article
    update_ticket(ticket: @ticket)
    update_ticket_history_entry(history_type)
    notify_agents

    schedule_reminder_job
  end

  private

  def ticket_done?
    state_ids = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    state_ids.include?(@ticket.state_id)
  end

  def emoji
    message.fetch(:emoji, nil)
  end

  def find_related_article
    Ticket::Article.where(message_id: message[:message_id])&.first
  end

  def update_related_article
    @related_article.update!(update_related_article_attributes)
  end

  def update_related_article_attributes
    preferences = @related_article.preferences
    preferences[:whatsapp] ||= {}
    preferences[:whatsapp][:reaction] = {
      emoji:  emoji,
      author: user.fullname
    }

    { preferences: }
  end

  def determine_history_type
    return 'created' if @related_article.preferences[:whatsapp]&.fetch(:reaction, nil).nil?

    emoji.nil? ? 'removed' : 'updated'
  end

  def update_ticket_history_entry(history_type)
    History.add(
      history_type:           history_type,
      history_object:         'Ticket::Article',
      history_attribute:      'reaction',
      o_id:                   @related_article.id,
      related_history_object: 'Ticket',
      related_o_id:           @ticket.id,
      value_from:             @related_article.created_by.fullname,
      value_to:               emoji || '',
      created_by_id:          @user.id,
    )
  end

  def notify_agents
    return if emoji.nil?

    TransactionJob.perform_now(
      object:     'Ticket::Article',
      type:       'update.reaction',
      object_id:  @related_article.ticket.id,
      article_id: @related_article.id,
      user_id:    @user.id,
    )
  end
end
