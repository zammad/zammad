# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Incoming < SecureMailing::Backend::HandlerIncoming
  EXPRESSION_MIME      = %r{application/(x-pkcs7|pkcs7)-mime}i
  EXPRESSION_SIGNATURE = %r{(application/(x-pkcs7|pkcs7)-signature|signed-data)}i

  OPENSSL_PKCS7_VERIFY_FLAGS = OpenSSL::PKCS7::NOVERIFY | OpenSSL::PKCS7::NOINTERN

  def type
    'S/MIME'
  end

  def signed?(check_content_type = content_type)
    EXPRESSION_SIGNATURE.match?(check_content_type)
  end

  def signed_type
    @signed_type ||= begin
      # Special wrapped mime-type S/MIME signature check (e.g. for Microsoft Outlook).
      if content_type.include?('signed-data') && EXPRESSION_MIME.match?(content_type)
        'wrapped'
      else
        'inline'
      end
    end
  end

  def encrypted?(check_content_type = content_type)
    EXPRESSION_MIME.match?(check_content_type)
  end

  def decrypt
    return if !encrypted?

    success = false
    comment = __('The private key for decryption could not be found.')

    decryption_certificates.each do |cert|
      key = OpenSSL::PKey::RSA.new(cert.private_key, cert.private_key_secret)

      begin
        decrypted_data = decrypt_p7enc.decrypt(key, cert.parsed)
      rescue
        next
      end

      parse_decrypted_mail(decrypted_data)

      success = true
      comment = cert.parsed.subject.to_s
      if !cert.parsed.usable?
        comment += " (Certificate #{cert.fingerprint} with start date #{cert.parsed.not_before} and end date #{cert.parsed.not_after} expired!)"
      end

      break
    end

    set_article_preferences(
      operation: :encryption,
      comment:   comment,
      success:   success,
    )
  end

  def verify_signature
    return if !signed?

    success = false
    comment = __('The certificate for verification could not be found.')

    result = verify_certificate_chain(verify_sign_p7enc.certificates)
    if result.present?
      success = true
      comment = result

      if signed_type == 'wrapped'
        parse_decrypted_mail(verify_sign_p7enc.data)
      end

      mail[:attachments].delete_if do |attachment|
        signed?(attachment.dig(:preferences, 'Content-Type'))
      end

      if !sender_is_signer?
        success = false
        comment = __('This message was not signed by its sender.')
      end
    end

    set_article_preferences(
      operation: :sign,
      comment:   comment,
      success:   success,
    )
  end

  def verify_certificate_chain(certificates)
    return if certificates.blank?

    subjects       = certificates.map(&:subject)
    subject_hashes = subjects.map { |subject| subject.hash.to_s(16) }
    return if subject_hashes.blank?

    # Try to find CA/Public key for the sender certificate
    # 1. In the SMIME store with the mail chain certifiates (reordered)
    # 2. In the SMIME store with the issuer of the sender certificate
    # 3. In the SSL store with the issuer of the sender certificate
    certificates_by_mail_chain = ::SMIMECertificate.where(subject_hash: subject_hashes).sort_by do |certificate|
      subject_hashes.index(certificate.parsed.subject.hash.to_s(16))
    end.presence
    certificate_by_issuer_smime_store = ::SMIMECertificate.where(subject_hash: certificates.first.issuer.hash.to_s(16)).presence
    certificate_by_issuer_ssl_store   = ::SSLCertificate.where(subject: certificates.first.issuer.to_s, ca: true).filter_map do |cert|
      ::SMIMECertificate.new(public_key: cert.certificate)
    rescue
      next
    end.presence
    existing_certs = certificates_by_mail_chain || certificate_by_issuer_smime_store || certificate_by_issuer_ssl_store

    return if existing_certs.blank?

    if subject_hashes.size > existing_certs.size
      existing_certs_subjects = existing_certs.map { |cert| cert.parsed.subject.to_s }.join(', ')
      Rails.logger.debug { "S/MIME mail signed with chain '#{subjects.join(', ')}' but only found '#{existing_certs_subjects}' in database." }
    end

    begin
      existing_certs_store = OpenSSL::X509::Store.new

      existing_certs.each do |existing_cert|
        existing_certs_store.add_cert(existing_cert.parsed)
      end

      success = verify_sign_p7enc.verify(certificates, existing_certs_store, nil, OPENSSL_PKCS7_VERIFY_FLAGS)
      return if !success

      existing_certs.map do |existing_cert|
        result = existing_cert.parsed.subject.to_s
        if !existing_cert.parsed.usable?
          result += " (Certificate #{existing_cert.fingerprint} with start date #{existing_cert.parsed.not_before} and end date #{existing_cert.parsed.not_after} expired!)"
        end
        result
      end.join(', ')
    rescue => e
      Rails.logger.error "Error while verifying mail with S/MIME certificate subjects: #{subjects}"
      Rails.logger.error e
      nil
    end
  end

  private

  def verify_sign_p7enc
    @verify_sign_p7enc ||= OpenSSL::PKCS7.read_smime(mail[:raw])
  end

  def decrypt_p7enc
    @decrypt_p7enc ||= OpenSSL::PKCS7.read_smime(mail[:raw])
  end

  def sender_is_signer?
    signers = email_addresses_from_subject_alt_name

    result = signers.include?(mail[:mail_instance].from.first.downcase)
    Rails.logger.warn { "S/MIME mail #{mail[:message_id]} signed by #{signers.join(', ')} but sender is #{mail[:mail_instance].from.first}" } if !result

    result
  end

  def email_addresses_from_subject_alt_name
    result = []

    @verify_sign_p7enc.certificates.each do |cert|
      subject_alt_name = cert.extensions.detect { |extension| extension.oid == 'subjectAltName' }
      next if subject_alt_name.nil?

      entries = subject_alt_name.value.split(%r{,\s?})
      entries.each do |entry|
        identifier, email_address = entry.split(':').map(&:downcase)

        next if identifier.exclude?('email') && identifier.exclude?('rfc822')
        next if !EmailAddressValidation.new(email_address).valid?

        result.push(email_address)
      end
    end

    result
  end

  def decryption_certificates
    certs = []

    mail[:mail_instance].to.each { |to| certs += ::SMIMECertificate.find_by_email_address(to, filter: { key: 'private', usage: :encryption }) }

    if mail[:mail_instance].cc.present?
      mail[:mail_instance].cc.each { |cc| certs += ::SMIMECertificate.find_by_email_address(cc, filter: { key: 'private', usage: :encryption }) }
    end

    certs
  end
end
