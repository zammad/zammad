# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::SecurityOptions < SecureMailing::Backend::HandlerSecurityOptions

  def type
    'S/MIME'
  end

  private

  def sign_security_options_status_default_message
    __('There was no certificate found.')
  end

  def config
    Setting.get('smime_config')
  end

  def group_has_valid_secure_objects?(signing_result, group_email)
    begin
      cert = SMIMECertificate.for_sender_email_address(from(group_email))

      return certificate_valid?(signing_result, cert, group_email)
    rescue => e
      signing_result.message = e.message
    end

    false
  end

  def certificate_valid?(signing_result, cert, email)
    result = false

    if cert
      result = !cert.expired?

      signing_result.message = if cert.expired?
                                 __('The certificate for %s was found, but has expired.')
                               else
                                 __('The certificate for %s was found.')
                               end
    else
      signing_result.message = __('The certificate for %s was not found.')
    end

    signing_result.message_placeholders = [email]

    result
  end

  def recipients_have_valid_secure_objects?(encryption_result, recipients)
    certs = SMIMECertificate.for_recipient_email_addresses!(recipients)

    certificates_valid?(encryption_result, certs, recipients)
  rescue => e
    encryption_result.message = e.message
    false
  end

  def certificates_valid?(encryption_result, certs, recipients)
    result = false

    if certs
      result = certs.none?(&:expired?)

      encryption_result.message = if certs.any?(&:expired?)
                                    __('There were certificates found for %s, but at least one of them has expired.')
                                  else
                                    __('The certificates for %s were found.')
                                  end
      encryption_result.message_placeholders = [recipients.join(', ')]
    else
      encryption_result.message = __('The certificates for %s were not found.')
    end

    result
  end
end
