# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SSLCertificate < ApplicationModel
  validate :valid_ssl_certificate

  before_validation :extract_metadata, on: :create

  def certificate_parsed
    @certificate_parsed ||= Certificate::X509::SSL.new(certificate)
  rescue OpenSSL::X509::CertificateError
    raise Exceptions::UnprocessableEntity, __('This is not a valid X509 certificate. Please check the certificate format.')
  end

  def filter_attributes(attributes)
    super.except! 'certificate'
  end

  private

  def extract_metadata
    cert = certificate_parsed
    self.fingerprint = cert.fingerprint
    self.subject     = cert.extensions_as_hash.fetch('subjectAltName', [cert.subject]).join(',')
    self.not_before  = cert.not_before
    self.not_after   = cert.not_after
    self.ca          = cert.ca?
  end

  def valid_ssl_certificate
    certificate_parsed.valid_ssl_certificate!
  rescue Exceptions::UnprocessableEntity => e
    errors.add(:base, e.message)
  end
end
