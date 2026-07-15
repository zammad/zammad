# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Incoming < SecureMailing::Backend::HandlerIncoming
  EXPRESSION_MIME      = %r{application/(x-pkcs7|pkcs7)-mime}i
  EXPRESSION_SIGNATURE = %r{(application/(x-pkcs7|pkcs7)-signature|signed-data)}i

  OPENSSL_PKCS7_VERIFY_FLAGS = OpenSSL::PKCS7::NOINTERN

  # Trust a stored certificate directly (without requiring a full CA chain up to it) and
  # do not fail chain building solely due to certificate expiry, since expired-but-trusted
  # certificates are handled separately via `existing_cert.parsed.usable?` below.
  OPENSSL_X509_STORE_FLAGS = OpenSSL::X509::V_FLAG_PARTIAL_CHAIN | OpenSSL::X509::V_FLAG_NO_CHECK_TIME

  # Real S/MIME certificate chains are only ever a handful of certificates. This bounds how
  # many candidates `signer_certificates` will run its expensive per-candidate check against,
  # so a mail bundling a large number of decorative certificates cannot force excessive work.
  MAX_BUNDLED_CERTIFICATES = 20

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
  rescue OpenSSL::PKCS7::PKCS7Error => e
    Rails.logger.error "Error while verifying mail with S/MIME signature: #{e}"
    set_article_preferences(
      operation: :sign,
      comment:   __('Error while verifying signature, please contact your administrator.'),
      success:   false,
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
      existing_certs_store.flags = OPENSSL_X509_STORE_FLAGS

      existing_certs.each do |existing_cert|
        existing_certs_store.add_cert(existing_cert.parsed)
      end

      success = verify_sign_p7enc.verify(certificates, existing_certs_store, nil, OPENSSL_PKCS7_VERIFY_FLAGS)
      return if !success

      comment = existing_certs.map do |existing_cert|
        result = existing_cert.parsed.subject.to_s
        if !existing_cert.parsed.usable?
          result += " (Certificate #{existing_cert.fingerprint} with start date #{existing_cert.parsed.not_before} and end date #{existing_cert.parsed.not_after} expired!)"
        end
        result
      end.join(', ')

      # `OPENSSL_X509_STORE_FLAGS` suppresses time-validity checking for the whole chain, not
      # just the trust anchor, so an expired signer certificate is otherwise never reported
      # when trust comes from a CA chain rather than a direct match against `existing_certs`.
      comment + expired_signer_certificate_notes(existing_certs)
    rescue => e
      Rails.logger.error "Error while verifying mail with S/MIME certificate subjects: #{subjects}"
      Rails.logger.error e
      nil
    end
  end

  private

  # Reported separately from `existing_certs` below since the actual signer certificate is
  # only among `existing_certs` for a direct match, not when trust comes from a CA chain.
  def expired_signer_certificate_notes(existing_certs)
    existing_fingerprints = existing_certs.map(&:fingerprint)

    signer_certificates.filter_map do |cert|
      smime_cert = Certificate::X509::SMIME.new(cert.to_pem)
      next if existing_fingerprints.include?(smime_cert.fingerprint)
      next if smime_cert.usable?

      " (Certificate #{smime_cert.fingerprint} with start date #{smime_cert.not_before} and end date #{smime_cert.not_after} expired!)"
    end.join
  end

  def verify_sign_p7enc
    @verify_sign_p7enc ||= OpenSSL::PKCS7.read_smime(verify_sign_raw)
  end

  # Captured once, since `mail[:raw]` is overwritten in place with the decrypted/unwrapped
  # content for wrapped mime-type S/MIME signatures (see `parse_decrypted_mail`), which would
  # no longer be parseable as the original PKCS7 structure by the time `signer_certificates`
  # (called later, from `sender_is_signer?`) needs to re-parse it.
  def verify_sign_raw
    @verify_sign_raw ||= mail[:raw]
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

  # Only the certificate(s) that actually produced the signature must be trusted for the
  # sender check. `verify_sign_p7enc.certificates` also contains any other certificates the
  # mail happens to bundle, which are attacker-controlled and must not be used to determine
  # the signer's identity. A candidate's `issuer`/`serial` fields are attacker-suppliable and
  # therefore not proof of authorship, so identity is established cryptographically instead:
  # a candidate only counts as a signer if its public key actually verifies the signature.
  # `PKCS7#verify` mutates its receiver's internal state, so each candidate is checked against
  # its own freshly parsed PKCS7 structure instead of the shared, memoized `verify_sign_p7enc`.
  # Memoized: this is called both from `verify_certificate_chain` (to report signer certificate
  # expiry) and from `sender_is_signer?`, and its per-candidate check is expensive.
  def signer_certificates
    @signer_certificates ||= begin
      if verify_sign_p7enc.certificates.size > MAX_BUNDLED_CERTIFICATES
        Rails.logger.warn { "S/MIME mail #{mail[:message_id]} bundles more than #{MAX_BUNDLED_CERTIFICATES} certificates, refusing to determine its signer." }
        []
      else
        signer_infos = verify_sign_p7enc.signers

        # Cheap optimization for the common case: narrow down to certificates whose issuer/serial
        # metadata matches a SignerInfo before running the expensive cryptographic check below.
        # This is not a security boundary by itself (issuer/serial are attacker-suppliable on a
        # self-signed certificate) — MAX_BUNDLED_CERTIFICATES above is what bounds worst-case cost.
        candidates = verify_sign_p7enc.certificates.select do |cert|
          signer_infos.any? { |info| info.issuer == cert.issuer && info.serial == cert.serial }
        end

        candidates.select do |cert|
          # NOVERIFY is safe (and required) here: this only tests whether `cert`'s public key
          # produced the signature, not whether it is trusted — trust was already established
          # for the overall message in `verify_certificate_chain` before this is ever called.
          OpenSSL::PKCS7.read_smime(verify_sign_raw).verify([cert], OpenSSL::X509::Store.new, nil, OpenSSL::PKCS7::NOVERIFY | OpenSSL::PKCS7::NOINTERN)
        end
      end
    end
  end

  def email_addresses_from_subject_alt_name
    result = []

    signer_certificates.each do |cert|
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

    if mail[:mail_instance].to.present?
      mail[:mail_instance].to.each { |to| certs += ::SMIMECertificate.find_by_email_address(to, filter: { key: 'private', usage: :encryption }) }
    end

    if mail[:mail_instance].cc.present?
      mail[:mail_instance].cc.each { |cc| certs += ::SMIMECertificate.find_by_email_address(cc, filter: { key: 'private', usage: :encryption }) }
    end

    certs
  end
end
