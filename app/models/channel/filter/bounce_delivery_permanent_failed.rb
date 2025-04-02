# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::BounceDeliveryPermanentFailed
  def self.run(_channel, mail, _transaction_params)
    return if !mail[:mail_instance]
    return if !mail[:mail_instance].bounced?
    return if !mail[:attachments]

    # remember, do not send notifications to certain recipients again if failed permanent
    mail[:attachments].each do |attachment|
      next if !attachment[:preferences]
      next if attachment[:preferences]['Mime-Type'] != 'message/rfc822'
      next if !attachment[:data]

      result = Channel::EmailParser.new.parse(attachment[:data], allow_missing_attribute_exceptions: false)
      next if !result[:message_id]

      # check user preferences
      next if mail[:mail_instance].action != 'failed'
      next if mail[:mail_instance].retryable? != false
      next if !match_error_status?(mail[:mail_instance].error_status)

      recipients = recipients_article(mail, result) || recipients_system_notification(mail, result)
      next if recipients.nil?

      # get recipient bounce mail, mark this user to not sent notifications anymore
      final_recipient = mail[:mail_instance].final_recipient
      if final_recipient.present?
        final_recipient.sub!(%r{rfc822;\s{0,10}}, '')
        if final_recipient.present?
          recipients.push final_recipient.downcase
        end
      end

      # set user preferences
      User.where(email: recipients.uniq).each do |user|
        next if !user

        user.preferences[:mail_delivery_failed] = true
        user.preferences[:mail_delivery_failed_data] = Time.zone.now
        user.save!
      end
    end

    true
  end

  def self.recipients_system_notification(_mail, bounce_email)
    return if bounce_email['date'].blank?

    date = bounce_email['date']
    message_id = bounce_email['message-id']
    return if message_id !~ %r{<notification\.\d+.(\d+).(\d+).[^>]+>}

    ticket = Ticket.lookup(id: $1)
    user   = User.lookup(id: $2)
    return if user.blank?
    return if ticket.blank?

    valid = ticket.history_get.any? do |row|
      next if row['created_at'] > date + 10.seconds
      next if row['created_at'] < date - 10.seconds
      next if row['type'] != 'notification'
      next if !row['value_to'].start_with?(user.email)

      true
    end

    return if valid.blank?

    [user.email]
  end

  # get recipient of origin article, if only one - mark this user to not sent notifications anymore
  def self.recipients_article(_mail, bounce_email)
    message_id_md5 = Digest::MD5.hexdigest(bounce_email[:message_id])
    article = Ticket::Article.where(message_id_md5: message_id_md5).reorder('created_at DESC, id DESC').limit(1).first
    return if !article
    return if article.sender.name != 'System' && article.sender.name != 'Agent'

    recipients = []
    %w[to cc].each do |line|
      next if article[line].blank?

      recipients = []
      begin
        list = Mail::AddressList.new(article[line])
        list.addresses.each do |address|
          next if address.address.blank?

          recipients.push address.address.downcase
        end
      rescue
        Rails.logger.info "Unable to parse email address in '#{article[line]}'"
      end
    end

    return [] if recipients.count > 1

    recipients
  end

  def self.match_error_status?(status)
    status == '5.1.1'
  end
end
