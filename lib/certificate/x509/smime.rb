# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Certificate::X509::SMIME < Certificate::X509
  include Certificate::X509::SMIME::Attributes

  attr_reader :email_addresses, :fingerprint, :issuer_hash, :uid, :subject_hash

  def self.parse(pem)
    begin
      new(pem)
    rescue OpenSSL::X509::CertificateError
      raise Exceptions::UnprocessableEntity, __('The certificate is not valid for S/MIME usage. Please check the certificate format.')
    end
  end

  def initialize(pem)
    super

    @email_addresses = fetch_email_addresses
    @subject_hash    = subject.hash.to_s(16)
    @issuer_hash     = issuer.hash.to_s(16)

    @uid = determine_uid
  end

  def rsa?
    public_key.class.name.end_with?('RSA')
  end

  def ec?
    public_key.class.name.end_with?('EC')
  end

  def applicable?
    return false if ca?

    # This is necessary because some legacy certificates may not have an extended key usage.
    extensions_as_hash.fetch('extendedKeyUsage', ['E-mail Protection']).include?('E-mail Protection')
  end

  def signature?
    return false if ca? || !applicable?

    # This is necessary because some legacy certificates may not have a key usage.
    extensions_as_hash.fetch('keyUsage', ['Digital Signature']).include?('Digital Signature')
  end

  def encryption?
    return false if ca? || !applicable?

    # This is necessary because some legacy certificates may not have a key usage.
    extensions_as_hash.fetch('keyUsage', ['Key Encipherment']).include?('Key Encipherment')
  end

  def valid_smime_certificate?
    return true if ca?

    return false if !applicable?
    return false if !signature? && !encryption?
    return false if @email_addresses.blank?
    return false if !rsa? && !ec?

    true
  end

  def valid_smime_certificate!
    return if valid_smime_certificate?

    message = __('The certificate is not valid for S/MIME usage. Please check the key usage, subject alternative name and public key cryptographic algorithm.')

    Rails.logger.error { "Certificate::X509::SMIME: #{message}" }
    Rails.logger.error { "Certificate::X509::SMIME:\n #{to_text}" }

    raise Exceptions::UnprocessableEntity, message
  end
end
