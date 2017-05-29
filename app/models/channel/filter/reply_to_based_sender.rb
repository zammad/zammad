# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::ReplyToBasedSender

  def self.run(_channel, mail)

    reply_to = mail['reply-to'.to_sym]
    return if reply_to.blank?

    setting = Setting.get('postmaster_sender_based_on_reply_to')
    return if setting.blank?

    # get properties of reply-to header
    result = Channel::EmailParser.sender_properties(reply_to)

    if setting == 'as_sender_of_email'
      mail[:from]              = reply_to
      mail[:from_email]        = result[:from_email]
      mail[:from_local]        = result[:from_local]
      mail[:from_domain]       = result[:from_domain]
      mail[:from_display_name] = result[:from_display_name]
      return
    end

    if setting == 'as_sender_of_email_use_from_realname'
      mail[:from]        = reply_to
      mail[:from_email]  = result[:from_email]
      mail[:from_local]  = result[:from_local]
      mail[:from_domain] = result[:from_domain]
      return
    end

    Rails.logger.error "Invalid setting value for 'postmaster_sender_based_on_reply_to' -> #{setting.inspect}"
  end

end
