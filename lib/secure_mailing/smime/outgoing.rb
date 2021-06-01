# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SecureMailing::SMIME::Outgoing < SecureMailing::Backend::Handler

  def initialize(mail, security)
    super()

    @mail     = mail
    @security = security
  end

  def process
    return if !process?

    @mail = workaround_mail_bit_encoding_issue(@mail)

    if @security[:sign][:success] && @security[:encryption][:success]
      processed = encrypt(signed)
      log('sign', 'success')
      log('encryption', 'success')
    elsif @security[:sign][:success]
      processed = Mail.new(signed)
      log('sign', 'success')
    elsif @security[:encryption][:success]
      processed = encrypt(@mail.encoded)
      log('encryption', 'success')
    end

    overwrite_mail(processed)
  end

  def process?
    return false if @security.blank?
    return false if @security[:type] != 'S/MIME'

    @security[:sign][:success] || @security[:encryption][:success]
  end

  # S/MIME signing fails because of message encoding #3147
  # workaround for https://github.com/mikel/mail/issues/1190
  def workaround_mail_bit_encoding_issue(mail)

    # change 7bit/8bit encoding to binary so that
    # base64 will be used to encode the content
    if mail.body.encoding.include?('bit')
      mail.body.encoding = :binary
    end

    # go into recursion for nested parts
    mail.parts&.each do |part|
      workaround_mail_bit_encoding_issue(part)
    end

    mail
  end

  def overwrite_mail(processed)
    @mail.body = nil
    @mail.body = processed.body.encoded

    @mail.content_disposition       = processed.content_disposition
    @mail.content_transfer_encoding = processed.content_transfer_encoding
    @mail.content_type              = processed.content_type
  end

  def signed
    from       = @mail.from.first
    cert_model = SMIMECertificate.for_sender_email_address(from)
    raise "Unable to find ssl private key for '#{from}'" if !cert_model
    raise "Expired certificate for #{from} (fingerprint #{cert_model.fingerprint}) with #{cert_model.not_before_at} to #{cert_model.not_after_at}" if !@security[:sign][:allow_expired] && cert_model.expired?

    private_key = OpenSSL::PKey::RSA.new(cert_model.private_key, cert_model.private_key_secret)

    OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.sign(cert_model.parsed, private_key, @mail.encoded, chain(cert_model), OpenSSL::PKCS7::DETACHED))
  rescue => e
    log('sign', 'failed', e.message)
    raise
  end

  def chain(cert)
    lookup_issuer = cert.parsed.issuer.to_s

    result = []
    loop do
      found_cert = SMIMECertificate.find_by(subject: lookup_issuer)
      break if found_cert.blank?

      subject       = found_cert.parsed.subject.to_s
      lookup_issuer = found_cert.parsed.issuer.to_s

      result.push(found_cert.parsed)

      # we've reached the root CA
      break if subject == lookup_issuer
    end
    result
  end

  def encrypt(data)
    certificates = SMIMECertificate.for_recipipent_email_addresses!(@mail.to)
    expired_cert = certificates.detect(&:expired?)
    raise "Expired certificates for cert with #{expired_cert.not_before_at} to #{expired_cert.not_after_at}" if !@security[:encryption][:allow_expired] && expired_cert.present?

    Mail.new(OpenSSL::PKCS7.write_smime(OpenSSL::PKCS7.encrypt(certificates.map(&:parsed), data, cipher)))
  rescue => e
    log('encryption', 'failed', e.message)
    raise
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new('AES-128-CBC')
  end

  def log(action, status, error = nil)
    HttpLog.create(
      direction:     'out',
      facility:      'S/MIME',
      url:           "#{@mail[:from]} -> #{@mail[:to]}",
      status:        status,
      ip:            nil,
      request:       @security,
      response:      { error: error },
      method:        action,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
