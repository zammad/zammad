# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::HandlerOutgoing < SecureMailing::Backend::Handler
  attr_accessor :mail, :security

  def initialize(mail, security)
    super()

    @mail     = mail
    @security = security
  end

  def process
    return if !process?

    workaround_mail_bit_encoding_issue(mail) if type.eql?('S/MIME')

    overwrite_mail(do_process)
  end

  def process?
    return false if security.blank?
    return false if security[:type] != type

    security[:sign][:success] || security[:encryption][:success]
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
    mail.body = nil
    mail.body = processed.body.encoded

    mail.content_disposition       = processed.content_disposition
    mail.content_transfer_encoding = processed.content_transfer_encoding
    mail.content_type              = processed.content_type
  end

  def log(action, status, error = nil)
    recipients = %i[to cc].map { |recipient| mail[recipient] }.join(' ').strip!
    HttpLog.create(
      direction:     'out',
      facility:      type,
      url:           "#{mail[:from]} -> #{recipients}",
      status:        status,
      ip:            nil,
      request:       security,
      response:      { error: error },
      method:        action,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  private

  def do_process
    if security[:sign][:success] && security[:encryption][:success]
      perform_sign_and_encrypt
    elsif security[:sign][:success]
      perform_sign
    elsif security[:encryption][:success]
      perform_encrypt
    end
  end

  def perform_sign_and_encrypt
    new_mail = encrypt(signed.encoded)

    log('sign', 'success')
    log('encryption', 'success')

    new_mail
  end

  def perform_sign
    new_mail = signed
    log('sign', 'success')

    new_mail
  end

  def perform_encrypt
    new_mail = encrypt(mail.encoded)
    log('encryption', 'success')

    new_mail
  end
end
