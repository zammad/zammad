# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sendmail
  include Channel::EmailHelper

  def send(_options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set system_bcc of config if defined
    system_bcc = Setting.get('system_bcc')
    email_address_validation = EmailAddressValidation.new(system_bcc)
    if system_bcc.present? && email_address_validation.valid?
      attr[:bcc] ||= ''
      attr[:bcc] += ', ' if attr[:bcc].present?
      attr[:bcc] += system_bcc
    end
    attr = prepare_idn_outbound(attr)

    mail = Channel::EmailBuild.build(attr, notification)
    delivery_method(mail)
    mail.deliver
  end

  private

  def delivery_method(mail)
    if ENV['ZAMMAD_MAIL_TO_FILE'].present?
      return mail.delivery_method :file, { location: Rails.root.join('tmp/mails'), extension: '.eml' }
    end

    return mail.delivery_method :test if Rails.env.test?

    mail.delivery_method :sendmail
  end
end
