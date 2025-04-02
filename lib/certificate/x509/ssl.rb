# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Certificate::X509::SSL < Certificate::X509

  def applicable?
    return true if ca?

    # This is necessary because some legacy certificates may not have an extended key usage.
    return false if !extensions_as_hash.fetch('keyUsage', ['Digital Signature']).intersect?(['Digital Signature', 'Certificate Sign']) # rubocop:disable Zammad/DetectTranslatableString

    tls_web_server_authentication? || tls_web_client_authentication?
  end

  def valid_ssl_certificate!
    return if applicable? && usable?

    message = __('The certificate is not valid for SSL usage. Please check e.g. the validity period or the extensions.')

    Rails.logger.error { "Certificate::X509::SSL: #{message}" }
    Rails.logger.error { "Certificate::X509::SSL:\n #{to_text}" }

    raise Exceptions::UnprocessableEntity, message
  end

  private

  def tls_web_client_authentication?
    extensions_as_hash.fetch('extendedKeyUsage', ['TLS Web Client Authentication']).include?('TLS Web Client Authentication')
  end

  def tls_web_server_authentication?
    extensions_as_hash.fetch('extendedKeyUsage', ['TLS Web Server Authentication']).include?('TLS Web Server Authentication')
  end
end
