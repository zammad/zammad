# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      cert = SMIMECertificate.find_by_email_address(from(group_email), filter: { key: 'private', usage: :signature, ignore_usable: true }).first
      return certificate_valid?(signing_result, cert, group_email)
    rescue => e
      signing_result.message = e.message
    end

    false
  end

  def certificate_valid?(signing_result, cert, email)
    result = false

    if cert
      result = cert.parsed.usable?

      signing_result.message = if cert.parsed.usable?
                                 __('The certificate for %s was found.')
                               else
                                 __('The certificate for %s was found, but it is not valid yet or has expired.')
                               end
    else
      signing_result.message = __('The certificate for %s was not found.')
    end

    signing_result.message_placeholders = [email]

    result
  end

  def recipients_have_valid_secure_objects?(encryption_result, recipients)
    certs = SMIMECertificate.find_for_multiple_email_addresses!(recipients, filter: { key: 'public', usage: :encryption, ignore_usable: true }, blame: true)

    certificates_valid?(encryption_result, certs, recipients)
  rescue => e
    encryption_result.message = e.message
    false
  end

  def certificates_valid?(encryption_result, certs, recipients)
    result = false

    if certs
      result = certs.none? { |cert| !cert.parsed.usable? }

      encryption_result.message = if certs.any? { |cert| !cert.parsed.usable? }
                                    __('There were certificates found for %s, but at least one of them is not valid yet or has expired.')
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
