class SecureMailing::SMIME::Incoming < SecureMailing::Backend::Handler

  EXPRESSION_MIME      = %r{application/(x-pkcs7|pkcs7)-mime}i.freeze
  EXPRESSION_SIGNATURE = %r{application/(x-pkcs7|pkcs7)-signature}i.freeze

  OPENSSL_PKCS7_VERIFY_FLAGS = OpenSSL::PKCS7::NOVERIFY | OpenSSL::PKCS7::NOINTERN

  def initialize(mail)
    super()

    @mail = mail
    @content_type = @mail[:mail_instance].content_type
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
      @mail[ key ] ||= {}
      @mail[ key ]
    end
  end

  def process?
    signed? || smime?
  end

  def signed?(content_type = @content_type)
    EXPRESSION_SIGNATURE.match?(content_type)
  end

  def smime?(content_type = @content_type)
    EXPRESSION_MIME.match?(content_type)
  end

  def decrypt
    return if !smime?

    success = false
    comment = 'Unable to find private key to decrypt'
    ::SMIMECertificate.where.not(private_key: [nil, '']).find_each do |cert|
      key = OpenSSL::PKey::RSA.new(cert.private_key, cert.private_key_secret)

      begin
        decrypted_data = p7enc.decrypt(key, cert.parsed)
      rescue
        next
      end

      @mail[:mail_instance].header['Content-Type'] = nil
      @mail[:mail_instance].header['Content-Disposition'] = nil
      @mail[:mail_instance].header['Content-Transfer-Encoding'] = nil
      @mail[:mail_instance].header['Content-Description'] = nil

      new_raw_mail = "#{@mail[:mail_instance].header}#{decrypted_data}"

      mail_new = Channel::EmailParser.new.parse(new_raw_mail)
      mail_new.each do |local_key, local_value|
        @mail[local_key] = local_value
      end

      success = true
      comment = cert.subject
      if cert.expired?
        comment += " (Certificate #{cert.fingerprint} with start date #{cert.not_before_at} and end date #{cert.not_after_at} expired!)"
      end

      # overwrite content_type for signature checking
      @content_type = @mail[:mail_instance].content_type
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
    comment = 'Unable to find certificate for verification'
    ::SMIMECertificate.find_each do |cert|
      verify_certs = []
      verify_ca    = OpenSSL::X509::Store.new

      if cert.parsed.issuer.to_s == cert.parsed.subject.to_s
        verify_ca.add_cert(cert.parsed)

        # CA
        verify_certs = p7enc.certificates.select do |message_cert|
          message_cert.issuer.to_s == cert.parsed.subject.to_s && verify_ca.verify(message_cert)
        end
      else

        # normal
        verify_certs.push(cert.parsed)
      end

      success = p7enc.verify(verify_certs, verify_ca, nil, OPENSSL_PKCS7_VERIFY_FLAGS)
      next if !success

      comment = cert.subject
      if cert.expired?
        comment += " (Certificate #{cert.fingerprint} with start date #{cert.not_before_at} and end date #{cert.not_after_at} expired!)"
      end
      break
    rescue => e
      success = false
      comment = e.message
    end

    if success
      @mail[:attachments].delete_if do |attachment|
        signed?(attachment.dig(:preferences, 'Content-Type'))
      end
    end

    article_preferences[:security][:sign] = {
      success: success,
      comment: comment,
    }
  end

  def p7enc
    OpenSSL::PKCS7.read_smime(@mail[:raw])
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
        url:           "#{@mail[:from]} -> #{@mail[:to]}",
        status:        status,
        ip:            nil,
        request:       {
          message_id: @mail[:message_id],
        },
        response:      article_preferences[:security],
        method:        action,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end
  end
end
