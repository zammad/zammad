# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Outgoing < SecureMailing::Backend::HandlerOutgoing
  def type
    'S/MIME'
  end

  def signed
    from       = mail.from.first
    cert_model = SMIMECertificate.find_by_email_address(from, filter: { key: 'private', usage: :signature, ignore_usable: true }).first
    raise "Unable to find ssl private key for '#{from}'" if !cert_model
    raise "Expired certificate for #{from} (fingerprint #{cert_model.fingerprint}) with #{cert_model.parsed.not_before} to #{cert_model.parsed.not_after}" if !security[:sign][:allow_expired] && !cert_model.parsed.usable?

    private_key = OpenSSL::PKey::RSA.new(cert_model.private_key, cert_model.private_key_secret)

    Mail.new(OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.sign(cert_model.parsed, private_key, mail.encoded, chain(cert_model), OpenSSL::PKCS7::DETACHED)))
  rescue => e
    log('sign', 'failed', e.message)
    raise
  end

  def chain(cert)
    lookup_issuer_hash = cert.parsed.issuer_hash

    result = []
    loop do
      found_cert = SMIMECertificate.find_by(subject_hash: lookup_issuer_hash)
      break if found_cert.blank?

      subject_hash       = found_cert.parsed.subject_hash
      lookup_issuer_hash = found_cert.parsed.issuer_hash

      result.push(found_cert.parsed)

      # we've reached the root CA
      break if subject_hash == lookup_issuer_hash
    end
    result
  end

  def encrypt(data)
    unusable_cert = certificates.detect { |cert| !cert.parsed.usable? }
    raise "Unusable certificates for cert with #{unusable_cert.parsed.not_before} to #{unusable_cert.parsed.not_after}" if !security[:encryption][:allow_expired] && unusable_cert.present?

    Mail.new(OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.encrypt(certificates.map(&:parsed), data, cipher)))
  rescue => e
    log('encryption', 'failed', e.message)
    raise
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new('AES-128-CBC')
  end

  private

  def certificates
    certificates = []
    %w[to cc].each do |recipient|
      addresses = mail.send(recipient)
      next if !addresses

      certificates += SMIMECertificate.find_for_multiple_email_addresses!(addresses, filter: { key: 'public', ignore_usable: true, usage: :encryption }, blame: true)
    end
    certificates
  end
end
