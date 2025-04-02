# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::BaseEmailOutbound
  include Channel::EmailHelper

  def deliver(_options, _attr, _notification = false) # rubocop:disable Style/OptionalBooleanParameter
    raise 'not implemented'
  end

  def prepare_message_attrs(attr)
    # set system_bcc of config if defined
    system_bcc = Setting.get('system_bcc')
    email_address_validation = EmailAddressValidation.new(system_bcc)
    if system_bcc.present? && email_address_validation.valid?
      attr[:bcc] ||= ''
      attr[:bcc] += ', ' if attr[:bcc].present?
      attr[:bcc] += system_bcc
    end

    prepare_idn_outbound(attr)
  end

  def deliver_mail(attr, notification, method, options = {})
    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method method, options
    mail.deliver
  end
end
