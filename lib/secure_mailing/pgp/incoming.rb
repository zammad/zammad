# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP::Incoming < SecureMailing::Backend::HandlerIncoming
  attr_accessor :mime_type, :content_type_parameters

  ENCRYPTION_CONTENT_TYPE     = 'application/pgp-encrypted'.freeze
  ENCRYPTED_PART_CONTENT_TYPE = 'application/octet-stream'.freeze
  SIGNATURE_CONTENT_TYPE      = 'application/pgp-signature'.freeze

  def initialize(mail)
    super

    @mime_type = mail[:mail_instance].mime_type
    @content_type_parameters = mail[:mail_instance].content_type_parameters
  end

  def type
    'PGP'
  end

  def encrypted?
    content_type.present? && mime_type.eql?('multipart/encrypted') && content_type_parameters[:protocol].eql?(ENCRYPTION_CONTENT_TYPE)
  end

  def signed?
    content_type.present? && mime_type.eql?('multipart/signed') && content_type_parameters[:protocol].eql?(SIGNATURE_CONTENT_TYPE)
  end

  def decrypt
    return if !decryptable?

    cipher_part = cipher_part_meta_check
    return if cipher_part.nil?

    return if !decrypt_body(cipher_part.body.decoded)

    set_article_preferences(
      operation: :encryption,
      success:   true,
      comment:   '',
    )
  end

  def verify_signature
    return if !verifiable?

    signature_part = signature_part_meta_check
    return if signature_part.nil?

    verified_result(signature_part.body.decoded)

    set_article_preferences(
      operation: :sign,
      success:   true,
      comment:   __('Good signature'),
    )
  end

  private

  def update_instance_meta_information
    # Overwrite mime type and content type parameters for decrypted mail.
    @mime_type               = mail[:mail_instance].mime_type
    @content_type_parameters = mail[:mail_instance].content_type_parameters
  end

  def result_success?(result)
    result[:status].success?
  end

  def result_comment(result)
    result[:stdout] || result[:stderr] || ''
  end

  def mail_part_check(operation)
    return true if mail[:mail_instance].parts.length.eql?(2)

    set_article_preferences(
      operation: operation,
      comment:   __('This PGP email does not have exactly two body parts for PGP mails as mandated by RFC 3156.'),
    )

    false
  end

  def signature_part_meta_check
    signature_part = mail[:mail_instance].parts[1]

    return signature_part if signature_part.has_content_type? && signature_part.mime_type.eql?(SIGNATURE_CONTENT_TYPE)

    set_article_preferences(
      operation: :sign,
      comment:   __('The signature part of this PGP email is missing or has a wrong content type according to RFC 3156.'),
    )

    nil
  end

  def version_part_check
    version_part = mail[:mail_instance].parts[0]
    return true if version_part.mime_type.eql?(ENCRYPTION_CONTENT_TYPE) && version_part.body.include?('Version: 1')

    set_article_preferences(
      operation: :encryption,
      comment:   __('The first part of this PGP email is not a valid version part as mandated by RFC 3156.'),
    )

    false
  end

  def cipher_part_meta_check
    cipher_part = mail[:mail_instance].parts[1]

    return cipher_part if cipher_part.has_content_type? && cipher_part.mime_type.eql?(ENCRYPTED_PART_CONTENT_TYPE)

    set_article_preferences(
      operation: :encryption,
      comment:   __('The encrypted part of this PGP email has an incorrect MIME type according to RFC 3156.'),
    )

    nil
  end

  def verifiable?
    return false if !signed?
    return false if !mail_part_check(:sign)
    return false if sign_keys.blank?

    true
  end

  def verified_result(signature)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      sign_keys.each { |key| pgp_tool.import(key.key) }

      begin
        pgp_tool.verify(verify_data, signature: signature)
      rescue => e
        set_article_preferences(
          operation: :sign,
          comment:   e.message,
        )
      end
    end
  end

  def verify_data
    raw_source = mail['raw']
    parts = raw_source.split(%r{^--#{mail[:mail_instance].boundary}\s$})[1..-2]

    "#{parts[0].strip}\r\n"
  end

  def decryptable?
    return false if !encrypted?
    return false if !mail_part_check(:encryption)
    return false if !version_part_check
    return false if decrypt_keys.blank?

    true
  end

  def decrypt_sign_verify_suppressed?(stderr)
    stderr.include?('gpg: signature verification suppressed')
  end

  def decrypt_body(data)
    result = decrypted_result(data)
    return false if result.nil?

    if !result[:status].success?
      set_article_preferences(
        operation: :encryption,
        comment:   result_comment(result)
      )
      return false
    end

    decrypted_body = result[:stdout]

    # If we're not getting a content type header, we need to add a newline, otherwise it's fucked up.
    if !decrypted_body.starts_with?('Content-Type:')
      decrypted_body = "\n#{decrypted_body}"
    end

    parse_decrypted_mail(decrypted_body)
    update_instance_meta_information

    check_signature(result[:stderr])

    true
  end

  def decrypted_result(data)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool| # rubocop:disable Metrics/BlockLength
      result = nil

      decrypt_keys.each do |key|
        pgp_tool.import(key.key)

        begin
          result = pgp_tool.decrypt(data, key.passphrase, skip_verify: true)
          check_signature_embedded(data, key, result[:stderr])
          break
        rescue SecureMailing::PGP::Tool::Error::NoData,
               SecureMailing::PGP::Tool::Error::BadPassphrase,
               SecureMailing::PGP::Tool::Error::NoPassphrase,
               SecureMailing::PGP::Tool::Error::UnknownError => e

          #  General decryption errors, no further checks needed.
          set_article_preferences(
            operation: :encryption,
            comment:   e.message,
          )

          break
        rescue SecureMailing::PGP::Tool::Error::NoSecretKey
          next
        rescue => e
          set_article_preferences(
            operation: :sign,
            comment:   e.message,
          )
          break
        end
      end

      result
    end
  end

  def check_signature_embedded(data, private_key, stderr)
    return if !decrypt_sign_verify_suppressed?(stderr)

    sign_comment = __('Good signature')
    sign_success = true

    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      sign_keys.each { |key| pgp_tool.import(key.key) }

      pgp_tool.import(private_key.key)

      begin
        pgp_tool.decrypt(data, private_key.passphrase)
      rescue SecureMailing::PGP::Tool::Error::NoPublicKey,
             SecureMailing::PGP::Tool::Error::ExpiredKey,
             SecureMailing::PGP::Tool::Error::RevokedKey,
             SecureMailing::PGP::Tool::Error::ExpiredSignature,
             SecureMailing::PGP::Tool::Error::BadSignature,
             SecureMailing::PGP::Tool::Error::ExpiredKeySignature,
             SecureMailing::PGP::Tool::Error::RevokedKeySignature => e

        sign_comment = e.message
        sign_success = false
      end
    end

    set_article_preferences(
      operation: :sign,
      comment:   sign_comment,
      success:   sign_success,
    )
  end

  def check_signature(result_output)
    return if !signed?
    return if result_output.empty?

    sign_success = false
    sign_comment = ''

    if result_output.include?('gpg: Good signature')
      sign_success = true
      sign_comment = __('Good signature')
    end

    set_article_preferences(
      operation: :sign,
      comment:   sign_comment,
      success:   sign_success,
    )
  end

  def sign_keys
    @sign_keys ||= pgp_keys(mail[:mail_instance].from.first, :sign, false)
  end

  def decrypt_keys
    @decrypt_keys ||= begin
      keys = []
      mail[:mail_instance].to.each { |to| keys += pgp_keys(to, :encryption, true) }

      if mail[:mail_instance].cc.present?
        mail[:mail_instance].cc.each { |cc| keys += pgp_keys(cc, :encryption, true) }
      end

      keys
    end
  end

  def pgp_keys(uid, operation, secret)
    records = PGPKey.find_all_by_uid(uid, only_valid: false, secret: secret)

    if records.empty?
      set_article_preferences(
        operation: operation,
        comment:   secret ? __('The private PGP key could not be found.') : __('The public PGP key could not be found.'),
      )
      return []
    end

    records
  end
end
