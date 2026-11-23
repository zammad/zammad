# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::BaseEmailOutbound
  include Channel::EmailHelper

  def deliver(_options, _attr, _notification = false, system_bcc: true) # rubocop:disable Style/OptionalBooleanParameter
    raise 'not implemented'
  end

  # A notification never carries the BCC of the system. An email that is sent in its place, but with
  #   every error raised, leaves it out with system_bcc: false.
  def prepare_message_attrs(attr, notification, system_bcc: true)
    prepare_bcc_header(attr) if system_bcc && !notification
    prepare_idn_outbound(attr)
  end

  def deliver_mail(attr, notification, method, options = {})
    mail = Channel::EmailBuild.build(attr, notification)

    begin
      mail.delivery_method method, options
      mail.deliver
    rescue => e
      # some SMTP error codes will be handled gracefully on notifications
      if notification && deliver_mail_notification_silence?(e, mail)
        return
      end

      raise e.class, humanized_error_message(e, options)
    end

  end

  private

  def deliver_mail_notification_silence?(_e, _mail)
    raise 'not implemented'
  end

  def humanized_error_message(e, options)
    identifier = server_identifier(options)

    case e
    when Net::OpenTimeout
      "Network connection to #{identifier} timed out: #{e.message}"
    when Errno::ECONNREFUSED
      "Network connection to #{identifier} could not be established: #{e.message}"
    when Net::SMTPAuthenticationError
      "Authentication on #{identifier} failed: #{e.message}"
    else
      "#{identifier}: #{e.message}"
    end
  end

  def server_identifier(_options)
    raise 'not implemented'
  end

  def prepare_bcc_header(attr)
    system_bcc = Setting.get('system_bcc')

    return if system_bcc.blank?

    email_address_validation = EmailAddressValidation.new(system_bcc)

    return if !email_address_validation.valid?

    attr[:bcc] ||= ''
    attr[:bcc] += ', ' if attr[:bcc].present?
    attr[:bcc] += system_bcc

    attr
  end
end
