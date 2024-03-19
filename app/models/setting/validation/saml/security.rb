# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Setting::Validation::Saml::Security < Setting::Validation::Base

  def run
    return result_success if value.blank? || disabled_security?

    %w[check_security_prerequisites check_private_key].each do |method|
      msg = send(method)
      next if msg.nil?

      return result_failed(msg)
    end

    cert = read_certificate
    return result_failed(__('The certificate could not be parsed.')) if cert.nil?

    msg = check_certificate(cert)

    {
      success: msg.nil?,
      message: msg,
    }
  end

  private

  def disabled_security?
    value.fetch('security', 'off').eql?('off')
  end

  def check_security_prerequisites
    return __('No certificate found.') if certificate_pem.blank?
    return __('No private key found.') if private_key_pem.blank?

    nil
  end

  def check_private_key
    begin
      private_key = OpenSSL::PKey.read(private_key_pem, private_key_secret)

      return __('The type of the private key is wrong.') if !private_key.class.name.end_with?('RSA')
      return __('The length of the private key is too short.') if private_key.n.num_bits < 2048
    rescue => e
      return e.message
    end

    nil
  end

  def read_certificate
    begin
      cert = Certificate::X509.new(certificate_pem)
    rescue
      return nil
    end

    cert
  end

  def check_certificate(cert)
    return __('The certificate is not usable due to being a CA certificate.') if cert.ca?
    return __('The certificate is not usable (e.g. expired).') if !cert.usable?
    return __('The certificate is not usable for signing and encryption.') if !cert.signature? || !cert.encryption?

    msg = check_cert_key_match(cert)
    return msg if !msg.nil?

    nil
  end

  def check_cert_key_match(cert)
    begin
      return __('The certificate does not match the given private key.') if !cert.key_match?(private_key_pem, private_key_secret)
    rescue => e
      return e.message
    end

    nil
  end

  def certificate_pem
    @certificate_pem ||= value.fetch('certificate', '')
  end

  def private_key_pem
    @private_key_pem ||= value.fetch('private_key', '')
  end

  def private_key_secret
    @private_key_secret ||= value.fetch('private_key_secret', '')
  end
end
