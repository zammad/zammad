# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::BounceDeliveryPermanentFailed

  def self.run(_channel, mail, _transaction_params)

    return if !mail[:mail_instance]
    return if !mail[:mail_instance].bounced?
    return if !mail[:attachments]

    # remember, do not send notifications to certain recipients again if failed permanent
    lines = %w[to cc]
    mail[:attachments].each do |attachment|
      next if !attachment[:preferences]
      next if attachment[:preferences]['Mime-Type'] != 'message/rfc822'
      next if !attachment[:data]

      result = Channel::EmailParser.new.parse(attachment[:data])
      next if !result[:message_id]

      message_id_md5 = Digest::MD5.hexdigest(result[:message_id])
      article = Ticket::Article.where(message_id_md5: message_id_md5).order('created_at DESC, id DESC').limit(1).first
      next if !article

      # check user preferences
      next if mail[:mail_instance].action != 'failed'
      next if mail[:mail_instance].retryable? != false
      next if mail[:mail_instance].error_status != '5.1.1'

      # get recipient of origin article, if only one - mark this user to not sent notifications anymore
      recipients = []
      if article.sender.name == 'System' || article.sender.name == 'Agent'
        lines.each do |line|
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
        if recipients.count > 1
          recipients = []
        end
      end

      # get recipient bounce mail, mark this user to not sent notifications anymore
      final_recipient = mail[:mail_instance].final_recipient
      if final_recipient.present?
        final_recipient.sub!(%r{rfc822;\s{0,10}}, '')
        if final_recipient.present?
          recipients.push final_recipient.downcase
        end
      end

      # set user preferences
      recipients.each do |recipient|
        users = User.where(email: recipient)
        users.each do |user|
          next if !user

          user.preferences[:mail_delivery_failed] = true
          user.preferences[:mail_delivery_failed_data] = Time.zone.now
          user.save!
        end
      end
    end

    true

  end
end
