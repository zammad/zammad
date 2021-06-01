# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::ReplyToBasedSender

  def self.run(_channel, mail, _transaction_params)

    reply_to = mail[:'reply-to']
    return if reply_to.blank?

    setting = Setting.get('postmaster_sender_based_on_reply_to')
    return if setting.blank?

    # remember original sender
    mail[:'raw-origin_from']        = mail[:'raw-from']
    mail[:origin_from]              = mail[:from]
    mail[:origin_from_email]        = mail[:from_email]
    mail[:origin_from_local]        = mail[:from_local]
    mail[:origin_from_domain]       = mail[:from_domain]
    mail[:origin_from_display_name] = mail[:from_display_name]

    # get properties of reply-to header
    result = Channel::EmailParser.sender_attributes(reply_to)

    if setting == 'as_sender_of_email'

      # set new sender
      mail[:'raw-from']        = mail[:'raw-reply-to']
      mail[:from]              = reply_to
      mail[:from_email]        = result[:from_email]
      mail[:from_local]        = result[:from_local]
      mail[:from_domain]       = result[:from_domain]
      mail[:from_display_name] = result[:from_display_name]
      return
    end

    if setting == 'as_sender_of_email_use_from_realname'

      # set new sender
      mail[:'raw-from']  = mail[:'raw-reply-to']
      mail[:from]        = reply_to
      mail[:from_email]  = result[:from_email]
      mail[:from_local]  = result[:from_local]
      mail[:from_domain] = result[:from_domain]
      return
    end

    Rails.logger.error "Invalid setting value for 'postmaster_sender_based_on_reply_to' -> #{setting.inspect}"
  end

end
