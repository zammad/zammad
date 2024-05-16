# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::Saml::TLS < Setting::Validation::Base

  def run
    return result_success if value.blank?

    msg = check_tls_verification
    return result_failed(msg) if !msg.nil?

    result_success
  end

  private

  def check_tls_verification
    return nil if !value[:ssl_verify]

    url = value[:idp_sso_target_url]
    return nil if !url.starts_with?('https://')

    resp = UserAgent.get(
      url,
      {},
      {
        verify_ssl: true,
        log:        { facility: 'SAML' }
      }
    )

    return nil if resp.error.nil?
    return nil if resp.error.starts_with?('#<Net::HTTP')

    Rails.logger.error("SAML: TLS verification failed for '#{url}': #{resp.error}")

    if resp.error.starts_with?('#<OpenSSL::SSL::SSLError')
      __('The verification of the TLS connection failed. Please check the SAML IDP certificate.')
    else
      __('The verification of the TLS connection is not possible. Please check the SAML IDP connection.')
    end
  end
end
