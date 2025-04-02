# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::NotificationSms < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    send_sms_notification
  end

  private

  def send_sms_notification
    if recipients.blank?
      Rails.logger.debug { "No SMS recipients found for Ticket# #{record.number}" }
      return
    end

    channel = Channel.find_by(area: 'Sms::Notification')
    if !channel.active?
      Rails.logger.info "Found possible SMS recipient(s) (#{recipients_to}) for Ticket##{record.number} but SMS channel is not active."
      return
    end

    create_notification_article(channel)
  end

  def create_notification_article(channel)
    # The attribute content_type is not needed for SMS.
    article = Ticket::Article.new(
      ticket_id:     id,
      subject:       'SMS notification',
      to:            recipients_to,
      body:          body,
      internal:      execution_data['internal'] || false, # default to public if value was not set
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'sms'),
      preferences:   {
        perform_origin: origin,
        sms_recipients: recipients_mobile,
        channel_id:     channel.id,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    article.history_change_source_attribute(performable, 'created')
    article.save!
  end

  def body
    NotificationFactory::Renderer.new(
      objects:  notification_factory_template_objects,
      template: execution_data['body'],
      escape:   false,
      locale:   locale,
      timezone: timezone,
    ).render.html2text.tr(' ', ' ') # convert non-breaking space to simple space
  end

  def recipients
    @recipients ||= Array(execution_data['recipient'])
      .each_with_object([]) { |recipient_type, sum| sum.concat(Array(recipients_by_type(recipient_type))) }
      .map { |user_or_id| user_or_id.is_a?(User) ? user_or_id : User.lookup(id: user_or_id) }
      .uniq(&:id)
      .select { |user| user.mobile.present? }
  end

  def recipients_to
    @recipients_to ||= recipients.map { |recipient| "#{recipient.fullname} (#{recipient.mobile})" }.join(', ')
  end

  def recipients_mobile
    @recipients_mobile ||= recipients.map(&:mobile)
  end

  def recipients_by_type(recipient_type)
    case recipient_type
    when 'article_last_sender'
      recipients_by_type_article_last_sender
    when 'ticket_customer'
      record.customer_id
    when 'ticket_owner'
      record.owner_id
    when 'ticket_agents'
      recipients_by_type_ticket_agents
    when %r{\Auserid_(\d+)\z}
      return $1 if User.exists?($1)

      Rails.logger.warn "Can't find configured #{origin} sms recipient user with ID '#{$1}'"
      nil
    else
      Rails.logger.error "Unknown sms notification recipient '#{recipient_type}'"
      nil
    end
  end

  def recipients_by_type_article_last_sender
    return nil if article.blank?

    if article.origin_by_id
      article.origin_by_id
    elsif article.created_by_id
      article.created_by_id
    end
  end

  def recipients_by_type_ticket_agents
    User.group_access(record.group_id, 'full').sort_by(&:login)
  end
end
