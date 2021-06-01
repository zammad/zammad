# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Sendmail
  def send(_options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set system_bcc of config if defined
    system_bcc = Setting.get('system_bcc')
    email_address_validation = EmailAddressValidation.new(system_bcc)
    if system_bcc.present? && email_address_validation.valid_format?
      attr[:bcc] ||= ''
      attr[:bcc] += ', ' if attr[:bcc].present?
      attr[:bcc] += system_bcc
    end

    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method delivery_method
    mail.deliver
  end

  private

  def delivery_method
    return :test if Rails.env.test?

    :sendmail
  end
end
