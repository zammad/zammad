# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::NotificationEmail < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    return if recipients_checked.blank?
    return if from_email_address.blank?

    send_email_notification
  end

  private

  def send_email_notification
    begin
      security = secure_mailing_notification
    rescue Exception::SecureMailing::Failure
      return
    end

    (body, attachments_inline) = article_body

    new_article = create_new_article(article_params(body, security))

    attachments_inline.each do |attachment|
      Store.create!(
        object:      'Ticket::Article',
        o_id:        new_article.id,
        data:        attachment[:data],
        filename:    attachment[:filename],
        preferences: attachment[:preferences],
      )
    end

    article_clone_attachments(new_article.id)
    article_clone_attachments_inline(new_article.id)
  end

  def create_new_article(params)
    new_article = Ticket::Article.new(params)
    new_article.history_change_source_attribute(performable, 'created')
    new_article.save!

    new_article
  end

  def article_params(body, security)
    {
      ticket_id:     id,
      to:            recipient_string,
      subject:       record.subject_build(article_subject),
      content_type:  'text/html',
      body:          body,
      internal:      execution_data['internal'] || false, # default to public if value was not set
      sender:        article_sender_system,
      type:          article_type_email,
      preferences:   article_preferences(security),
      updated_by_id: 1,
      created_by_id: 1,
    }
  end

  def article_clone_attachments(new_article_id)
    last_article = notification_factory_template_objects[:article]

    return if !last_article
    return if ActiveModel::Type::Boolean.new.cast(execution_data['include_attachments']) != true || last_article.attachments.blank?

    last_article.clone_attachments('Ticket::Article', new_article_id, only_attached_attachments: true)
  end

  def article_clone_attachments_inline(new_article_id)
    last_article = notification_factory_template_objects[:article]

    return if !last_article
    return if !last_article.should_clone_inline_attachments?

    last_article.clone_attachments('Ticket::Article', new_article_id, only_inline_attachments: true)
    last_article.should_clone_inline_attachments = false # cancel the temporary flag after cloning
  end

  def from_email_address
    @from_email_address ||= begin
      group = record.group
      email_address = group.email_address

      if !email_address
        Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because no email address is set for group '#{group.name}'"
        nil
      elsif !email_address.channel_id
        Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because no channel is set for email address '#{email_address.email}' (id: #{email_address.id})"
        nil
      elsif !email_address.channel.active
        Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because the channel for email address '#{email_address.email} is not active' (id: #{email_address.id})"
        nil
      else
        email_address
      end
    end
  end

  def article_subject
    NotificationFactory::Mailer.template(
      templateInline: execution_data['subject'],
      objects:        notification_factory_template_objects,
      quote:          false,
      locale:         locale,
      timezone:       timezone,
    )
  end

  def article_body
    body = NotificationFactory::Mailer.template(
      templateInline: execution_data['body'],
      objects:        notification_factory_template_objects,
      quote:          true,
      locale:         locale,
      timezone:       timezone,
    )

    HtmlSanitizer.replace_inline_images(body, id)
  end

  def article_preferences(security)
    preferences = {
      perform_origin: origin,
    }

    if security.present?
      preferences[:security] = security
    end

    preferences
  end

  def secure_mailing_notification
    return if !Setting.get('smime_integration') && !Setting.get('pgp_integration')

    security = nil
    if Setting.get('smime_integration')
      security = secure_mailing_notification_smime

      return security if security[:sign][:success] || security[:encryption][:success]
    end

    return security if !Setting.get('pgp_integration')

    secure_mailing_notification_pgp
  end

  def secure_mailing_notification_smime
    security = SecureMailing::SMIME::NotificationOptions.process(**secure_mailing_notification_process_params)

    if secure_mailing_notification_result_sign_failing?(security)
      Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because of missing group #{current_group_name} email #{from_email_address.email} certificate for signing (discarding notification)."

      raise Exception::SecureMailing::Failure
    end

    if secure_mailing_notification_result_encryption_failing?(security)
      Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because public certificate is not available for encryption (discarding notification)."

      raise Exception::SecureMailing::Failure
    end

    security
  end

  def secure_mailing_notification_pgp
    security = SecureMailing::PGP::NotificationOptions.process(**secure_mailing_notification_process_params)

    if secure_mailing_notification_result_sign_failing?(security)
      Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because of missing group #{current_group_name} email #{email_address.email} PGP key for signing (discarding notification)."

      raise Exception::SecureMailing::Failure
    end

    if secure_mailing_notification_result_encryption_failing?(security)
      Rails.logger.info "Unable to send trigger based notification to #{recipient_string} because public PGP keys are not available for encryption (discarding notification)."

      raise Exception::SecureMailing::Failure
    end

    security
  end

  def secure_mailing_notification_process_params
    {
      from:       from_email_address,
      recipients: recipients_checked,
      perform:    {
        sign:    secure_mailing_notification_sign,
        encrypt: secure_mailing_notification_encryption,
      },
    }
  end

  def secure_mailing_notification_result_sign_failing?(result)
    secure_mailing_notification_sign && execution_data['sign'] == 'discard' && !result[:sign][:success]
  end

  def secure_mailing_notification_result_encryption_failing?(result)
    secure_mailing_notification_encryption && execution_data['encryption'] == 'discard' && !result[:encryption][:success]
  end

  def secure_mailing_notification_sign
    @secure_mailing_notification_sign ||= execution_data['sign'].present? && execution_data['sign'] != 'no'
  end

  def secure_mailing_notification_encryption
    @secure_mailing_notification_encryption ||= execution_data['encryption'].present? && execution_data['encryption'] != 'no'
  end

  def recipients_raw
    @recipients_raw ||= Array(execution_data['recipient'])
      .each_with_object([]) { |recipient_type, sum| sum.concat(Array(recipients_by_type(recipient_type)).compact) }
  end

  def recipients_checked
    @recipients_checked ||= begin
      recipients_checked = []

      recipients_raw.each do |recipient_email|
        recipient_email = valid_recipient_address(recipient_email)
        next if recipient_email.blank?

        next if recipients_checked.include?(recipient_email)

        next if !send_recipient_notification?(recipient_email)

        recipients_checked.push(recipient_email)
      end

      recipients_checked
    end
  end

  def recipient_string
    @recipient_string ||= recipients_checked.join(', ')
  end

  def recipients_by_type(recipient_type)
    case recipient_type
    when 'article_last_sender'
      recipients_by_type_article_last_sender
    when 'ticket_customer'
      user_lookup_email(record.customer_id)
    when 'ticket_owner'
      user_lookup_email(record.owner_id)
    when 'ticket_agents'
      recipients_by_type_user_group_access
    when %r{\Auserid_(\d+)\z}
      return user_lookup_email($1) if User.exists?($1)

      Rails.logger.warn "Can't find configured #{origin} Email recipient User with ID '#{$1}'"
      nil
    else
      Rails.logger.error "Unknown email notification recipient '#{recipient_type}'"
      nil
    end
  end

  def recipients_by_type_article_last_sender
    return nil if article.blank?

    if article.reply_to
      article.reply_to
    elsif article.from
      article.from
    elsif article.origin_by_id
      user_lookup_email(article.origin_by_id)
    elsif article.created_by_id
      user_lookup_email(article.created_by_id)
    end
  end

  def recipients_by_type_user_group_access
    User.group_access(record.group_id, 'full').sort_by(&:login).map(&:email)
  end

  def user_lookup_email(id)
    User.find_by(id: id).email
  end

  def send_recipient_notification?(recipient_email)
    # do not send notification if system address
    return false if EmailAddress.exists?(email: recipient_email)

    return false if trigger_based_notification_blocked?(recipient_email)

    # do not sent notifications to this recipients or for auto response tagged incoming emails
    return false if send_no_auto_response?(recipient_email)

    # loop protection / check if maximal count of trigger mail has reached
    return false if ticket_trigger_loop_protection?(recipient_email)

    true
  end

  def trigger_based_notification_blocked?(recipient_email)
    users = User.where(email: recipient_email)

    users.any? do |user|
      blocked_in_days = trigger_based_notification_blocked_in_days(user)
      if blocked_in_days.zero?
        false
      else
        Rails.logger.info "Send no trigger based notification to #{user.email} because email is marked as mail_delivery_failed for #{blocked_in_days} day(s)"
        true
      end

    end
  end

  def trigger_based_notification_blocked_in_days(user)
    preferences = user.preferences

    return 0 if !preferences[:mail_delivery_failed]
    return 0 if preferences[:mail_delivery_failed_data].blank?

    # Blocked for 60 full days; see #4459.
    remaining_days = (preferences[:mail_delivery_failed_data].to_date - Time.zone.now.to_date).to_i + 61
    return remaining_days if remaining_days.positive?

    # Cleanup the user preferences
    trigger_based_notification_reset_blocking(user)

    0
  end

  def trigger_based_notification_reset_blocking(user)
    user.preferences[:mail_delivery_failed] = false
    user.preferences[:mail_delivery_failed_data] = nil
    user.save!
  end

  def valid_recipient_address(recipient_email)
    begin
      Mail::AddressList.new(recipient_email).addresses.each do |address|
        recipient_email = address.address
        email_address_validation = EmailAddressValidation.new(recipient_email)
        return recipient_email.downcase.strip if email_address_validation.valid?
      end
    rescue
      if recipient_email.present?
        if recipient_email !~ %r{^(.+?)<(.+?)@(.+?)>$}
          return nil # no usable format found
        end

        recipient_email = "#{$2}@#{$3}".downcase.strip

        email_address_validation = EmailAddressValidation.new(recipient_email)
        return recipient_email if email_address_validation.valid?
      end
    end

    nil
  end

  def send_no_auto_response?(recipient_email)
    # do not sent notifications to this recipients
    begin
      return true if recipient_email.match?(%r{#{send_no_auto_response_reg_exp}}i)
    rescue => e
      Rails.logger.error "Invalid regex '#{send_no_auto_response_reg_exp}' in setting send_no_auto_response_reg_exp"
      Rails.logger.error e
      return true if recipient_email.match?(%r{(mailer-daemon|postmaster|abuse|root|noreply|noreply.+?|no-reply|no-reply.+?)@.+?}i)
    end

    auto_response_from_customer?(recipient_email)
  end

  def send_no_auto_response_reg_exp
    @send_no_auto_response_reg_exp ||= Setting.get('send_no_auto_response_reg_exp')
  end

  def auto_response_from_customer?(recipient_email)
    # check if notification should be send because of customer emails
    if article.present? && article.preferences.fetch('is-auto-response', false) == true && article.from && article.from =~ %r{#{Regexp.quote(recipient_email)}}i
      Rails.logger.info "Send no trigger based notification to #{recipient_email} because of auto response tagged incoming email"
      return true
    end

    false
  end

  def ticket_trigger_loop_protection?(recipient_email)
    ticket_trigger_loop_protection_articles_per_ticket?(recipient_email) || ticket_trigger_loop_protection_articles_total?(recipient_email)
  end

  def ticket_trigger_loop_protection_articles_per_ticket?(recipient_email)
    ticket_trigger_loop_protection_articles_per_ticket_map.each do |minutes, count|
      already_sent = Ticket::Article.where(
        ticket_id: id,
        sender:    article_sender_system,
        type:      article_type_email,
      ).where('ticket_articles.created_at > ? AND ticket_articles.to LIKE ?', Time.zone.now - minutes.minutes, "%#{SqlHelper.quote_like(recipient_email)}%").count

      next if already_sent < count

      Rails.logger.error "Send no trigger based notification to #{recipient_email} because already sent #{count} for this ticket within last #{minutes} minutes (loop protection set by setting ticket_trigger_loop_protection_articles_per_ticket)"

      return true
    end

    false
  end

  def ticket_trigger_loop_protection_articles_per_ticket_map
    @ticket_trigger_loop_protection_articles_per_ticket_map ||= Setting.get('ticket_trigger_loop_protection_articles_per_ticket')
  end

  def ticket_trigger_loop_protection_articles_total?(recipient_email)
    ticket_trigger_loop_protection_articles_total_map.each do |minutes, count|
      already_sent = Ticket::Article.where(
        sender: article_sender_system,
        type:   article_type_email,
      ).where('ticket_articles.created_at > ? AND ticket_articles.to LIKE ?', Time.zone.now - minutes.minutes, "%#{SqlHelper.quote_like(recipient_email)}%").count
      next if already_sent < count

      Rails.logger.error "Send no trigger based notification to #{recipient_email} because already sent #{count} in total within last #{minutes} minutes (loop protection set by setting ticket_trigger_loop_protection_articles_total)"
      return true
    end

    false
  end

  def ticket_trigger_loop_protection_articles_total_map
    @ticket_trigger_loop_protection_articles_total_map ||= Setting.get('ticket_trigger_loop_protection_articles_total')
  end

  def article_sender_system
    @article_sender_system ||= Ticket::Article::Sender.find_by(name: 'System')
  end

  def article_type_email
    @article_type_email ||= Ticket::Article::Type.find_by(name: 'email')
  end

  def current_group_name
    record.group.name
  end
end
