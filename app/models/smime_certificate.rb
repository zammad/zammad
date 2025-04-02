# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SMIMECertificate < ApplicationModel
  default_scope { order(created_at: :desc, id: :desc) }

  validates :fingerprint, uniqueness: { case_sensitive: true }

  # public class methods

  def self.find_for_multiple_email_addresses!(addresses, filter: nil, blame: false)
    certificates      = []
    missing_addresses = []

    addresses.each do |address|
      certs = find_by_email_address(address, filter: filter)

      if certs.blank? && blame
        missing_addresses << address
        next
      end

      certificates.push(*certs)
    end

    if missing_addresses.present? && blame
      message = __('The certificate for %s was not found.')
      addresses = missing_addresses.join(', ')

      raise ActiveRecord::RecordNotFound, message % addresses
    end

    certificates
  end

  def self.find_by_email_address(address, filter: nil)
    cert_selector = SMIMECertificate.where(SqlHelper.new(object: SMIMECertificate).array_contains_one('email_addresses', address.downcase))

    return cert_selector.all if filter.nil?

    filter.each do |filter_key, filter_value|
      cert_selector = send(:"filter_#{filter_key}", cert_selector, filter_value)
      return [] if cert_selector.blank?
    end

    cert_selector
  end

  def self.create_certificates(pem)
    parts(pem).select { |part| part.include?('CERTIFICATE') }.each_with_object([]) do |part, result|
      result << create!(public_key: part)
    end
  end

  def self.create_private_keys(pem, secret)
    parts(pem).select { |part| part.include?('PRIVATE KEY') }.each do |part|
      private_key = SecureMailing::SMIME::PrivateKey.new(part, secret)
      private_key.valid_smime_private_key!

      certificate = find_by(uid: private_key.uid)
      raise Exceptions::UnprocessableEntity, __('The certificate for this private key could not be found.') if !certificate

      certificate.update!(private_key: private_key.pem, private_key_secret: secret)
    end
  end

  # private class methods

  def self.filter_ignore_usable(cert_selector, filter_value)
    return cert_selector if cert_selector.blank?
    return cert_selector if filter_value

    cert_selector.select { |cert| cert.parsed.usable? }
  end

  def self.filter_key(cert_selector, filter_value)
    raise ArgumentError, 'filter_value must be either "public" or "private"' if %w[public private].exclude?(filter_value.to_s)
    return cert_selector if cert_selector.blank?
    return cert_selector if filter_value.eql?('public')

    cert_selector.where.not(private_key: nil)
  end

  def self.filter_usage(cert_selector, filter_value)
    raise ArgumentError, 'filter_value must be either "signature" or "encryption"' if %w[signature encryption].exclude?(filter_value.to_s)
    return cert_selector if cert_selector.blank?

    cert_selector.select { |cert| cert.parsed.send(:"#{filter_value}?") }
  end

  def self.parts(pem)
    pem.scan(%r{-----BEGIN[^-]+-----.+?-----END[^-]+-----}m)
  end

  private_class_method %i[
    filter_ignore_usable
    filter_key
    filter_usage
    parts
  ]

  # public instance methods

  def parsed
    @parsed ||= Certificate::X509::SMIME.new(pem)
  end

  def public_key=(string)
    cert = Certificate::X509::SMIME.new(string)

    self.email_addresses = cert.email_addresses
    self.pem             = cert.to_pem

    # The fingerprint is a hash of the certificate in DER format.
    self.fingerprint = cert.fingerprint

    # The following both attributes are hashes of the certificate issuer and
    # subject strings.
    # They are used for certificate chain checks.
    #
    # Because of legacy certificates the usage of the x509 extension
    # "subjectKeyIdentifier" and "authorityKeyIdentifier" is not possible.
    self.issuer_hash  = cert.issuer_hash
    self.subject_hash = cert.subject_hash

    # This is a unique information of the public key.
    # It is used to find the corresponding private key.
    self.uid = cert.uid
  end
end
