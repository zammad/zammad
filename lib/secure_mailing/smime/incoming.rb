# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::Incoming < SecureMailing::Backend::Handler
  attr_accessor :mail, :content_type

  EXPRESSION_MIME      = %r{application/(x-pkcs7|pkcs7)-mime}i
  EXPRESSION_SIGNATURE = %r{(application/(x-pkcs7|pkcs7)-signature|signed-data)}i

  OPENSSL_PKCS7_VERIFY_FLAGS = OpenSSL::PKCS7::NOVERIFY | OpenSSL::PKCS7::NOINTERN

  def initialize(mail)
    super()

    @mail = mail
    @content_type = mail[:mail_instance].content_type
  end

  def process
    return if !process?

    initialize_article_preferences
    decrypt
    verify_signature
    log
  end

  def initialize_article_preferences
    article_preferences[:security] = {
      type:       'S/MIME',
      sign:       {
        success: false,
        comment: nil,
      },
      encryption: {
        success: false,
        comment: nil,
      }
    }
  end

  def article_preferences
    @article_preferences ||= begin
      key = :'x-zammad-article-preferences'
      mail[ key ] ||= {}
      mail[ key ]
    end
  end

  def process?
    signed? || smime?
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

  def smime?(check_content_type = content_type)
    EXPRESSION_MIME.match?(check_content_type)
  end

  def decrypt
    return if !smime?

    success = false
    comment = __('Private key for decryption could not be found.')
    ::SMIMECertificate.where.not(private_key: [nil, '']).find_each do |cert|
      key = OpenSSL::PKey::RSA.new(cert.private_key, cert.private_key_secret)

      begin
        decrypted_data = decrypt_p7enc.decrypt(key, cert.parsed)
      rescue
        next
      end

      parse_new_mail(decrypted_data)

      success = true
      comment = cert.subject
      if cert.expired?
        comment += " (Certificate #{cert.fingerprint} with start date #{cert.not_before_at} and end date #{cert.not_after_at} expired!)"
      end

      # overwrite content_type for signature checking
      @content_type = mail[:mail_instance].content_type
      break
    end

    article_preferences[:security][:encryption] = {
      success: success,
      comment: comment,
    }
  end

  def verify_signature
    return if !signed?

    success = false
    comment = __('Certificate for verification could not be found.')

    result = verify_certificate_chain(verify_sign_p7enc.certificates)
    if result.present?
      success = true
      comment = result

      if signed_type == 'wrapped'
        parse_new_mail(verify_sign_p7enc.data)
      end

      mail[:attachments].delete_if do |attachment|
        signed?(attachment.dig(:preferences, 'Content-Type'))
      end

      if !sender_is_signer?
        success = false
        comment = __('Message is not signed by sender.')
      end
    end

    article_preferences[:security][:sign] = {
      success: success,
      comment: comment,
    }
  end

  def verify_certificate_chain(certificates)
    return if certificates.blank?

    subjects = certificates.map(&:subject).map(&:to_s)
    return if subjects.blank?

    existing_certs = ::SMIMECertificate.where(subject: subjects).sort_by do |certificate|
      # ensure that we have the same order as the certificates in the mail
      subjects.index(certificate.subject)
    end
    return if existing_certs.blank?

    if subjects.size > existing_certs.size
      Rails.logger.debug { "S/MIME mail signed with chain '#{subjects.join(', ')}' but only found '#{existing_certs.map(&:subject).join(', ')}' in database." }
    end

    begin
      existing_certs_store = OpenSSL::X509::Store.new

      existing_certs.each do |existing_cert|
        existing_certs_store.add_cert(existing_cert.parsed)
      end

      success = verify_sign_p7enc.verify(certificates, existing_certs_store, nil, OPENSSL_PKCS7_VERIFY_FLAGS)
      return if !success

      existing_certs.map do |existing_cert|
        result = existing_cert.subject
        if existing_cert.expired?
          result += " (Certificate #{existing_cert.fingerprint} with start date #{existing_cert.not_before_at} and end date #{existing_cert.not_after_at} expired!)"
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

  def log
    %i[sign encryption].each do |action|
      result = article_preferences[:security][action]
      next if result.blank?

      if result[:success]
        status = 'success'
      elsif result[:comment].blank?
        # means not performed
        next
      else
        status = 'failed'
      end

      HttpLog.create(
        direction:     'in',
        facility:      'S/MIME',
        url:           "#{mail[:from]} -> #{mail[:to]}",
        status:        status,
        ip:            nil,
        request:       {
          message_id: mail[:message_id],
        },
        response:      article_preferences[:security],
        method:        action,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
  end

  def parse_new_mail(new_mail)
    mail[:mail_instance].header['Content-Type'] = nil
    mail[:mail_instance].header['Content-Disposition'] = nil
    mail[:mail_instance].header['Content-Transfer-Encoding'] = nil
    mail[:mail_instance].header['Content-Description'] = nil

    new_raw_mail = "#{mail[:mail_instance].header}#{new_mail}"

    mail_new = Channel::EmailParser.new.parse(new_raw_mail)
    mail_new.each do |local_key, local_value|
      mail[local_key] = local_value
    end
  end

  def sender_is_signer?
    signers = email_addresses_from_subject_alt_name

    result = signers.include?(mail[:mail_instance].from.first)
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
end
