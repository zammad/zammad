# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sendmail < Channel::Driver::BaseEmailOutbound
  include Channel::EmailHelper

  # Sends a message via Sendmail
  def deliver(_options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    attr = prepare_message_attrs(attr)

    deliver_mail(attr, notification)
  end

  private

  # Sendmail driver is (ab)used in testing and development environments
  #
  # Normally this driver sends mails via sendmail command
  # The special rails test adapter is used in testing
  #
  # ZAMMAD_MAIL_TO_FILE is for debugging outgoing mails.
  # It allows to easily inspect contents of the outgoing messsages
  def deliver_mail(attr, notification)
    if ENV['ZAMMAD_MAIL_TO_FILE'].present?
      super(attr, notification, :file, { location: Rails.root.join('tmp/mails'), extension: '.eml' })
    elsif Rails.env.test? && ENV['ZAMMAD_MAIL_PRETEND_NOT_TEST'] != '1'
      # test
      super(attr, notification, :test)
    else
      super(attr, notification, :sendmail)
    end
  end

  def server_identifier(_)
    'sendmail'
  end

  # Sendmail driver does not raise silenceable errors
  def deliver_mail_notification_silence?(_e, _mail)
    false
  end
end
