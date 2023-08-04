# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Certificate < OpenSSL::X509::Certificate
  include SecureMailing::SMIME::Certificate::Attributes

  attr_reader :email_addresses, :fingerprint, :issuer_hash, :uid, :subject_hash

  def self.parse(pem)
    begin
      new(pem)
    rescue OpenSSL::X509::CertificateError
      raise Exceptions::UnprocessableEntity, __('The certificate is not valid for S/MIME usage. Please check the certificate format.')
    end
  end

  def initialize(pem)
    super(pem.gsub(%r{(?:TRUSTED\s)?(CERTIFICATE---)}, '\1'))

    @email_addresses = fetch_email_addresses
    @fingerprint     = OpenSSL::Digest.new('SHA1', to_der).to_s
    @subject_hash    = subject.hash.to_s(16)
    @issuer_hash     = issuer.hash.to_s(16)

    @uid = determine_uid
  end

  def ca?
    return false if !extensions_as_hash.key?('basicConstraints')

    basic_constraints = extensions_as_hash['basicConstraints']
    return false if basic_constraints.exclude?('CA:TRUE')

    true
  end

  def rsa?
    public_key.class.name.end_with?('RSA')
  end

  def ec?
    public_key.class.name.end_with?('EC')
  end

  def effective?
    Time.zone.now >= not_before
  end

  def expired?
    Time.zone.now > not_after
  end

  def applicable?
    return false if ca?

    extended_key_usage = extensions_as_hash['extendedKeyUsage']

    # This is necessary because some legacy certificates may not have an extended key usage.
    return true if extended_key_usage.nil?

    extended_key_usage.include?('E-mail Protection')
  end

  def signature?
    return false if ca?

    key_usage = extensions_as_hash['keyUsage']

    # This is necessary because some legacy certificates may not have a key usage.
    return true if key_usage.nil?

    return false if !applicable?

    key_usage.include?('Digital Signature')
  end

  def encryption?
    return false if ca?

    key_usage = extensions_as_hash['keyUsage']

    # This is necessary because some legacy certificates may not have a key usage.
    return true if key_usage.nil?

    return false if !applicable?

    key_usage.include?('Key Encipherment')
  end

  def usable?
    effective? && !expired?
  end

  def valid_smime_certificate? # rubocop:disable Metrics/CyclomaticComplexity
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

    Rails.logger.error { "SMIME::Certificate: #{message}" }
    Rails.logger.error { "SMIME::Certificate:\n #{to_text}" }

    raise Exceptions::UnprocessableEntity, message
  end
end
