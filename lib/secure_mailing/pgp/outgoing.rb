# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP::Outgoing < SecureMailing::Backend::HandlerOutgoing
  def type
    'PGP'
  end

  def signed
    raise "Unable to find pgp private key for '#{from}'" if sign_key.nil?

    sign_key.expired!

    construct_signed_mail
  rescue => e
    log('sign', 'failed', e.message)
    raise
  end

  def encrypt(data)
    expired_key = keys.detect(&:expired?)
    raise "Expired key (fingerprint #{sign_key.fingerprint}) at #{expired_key.expires_at} present" if expired_key.present?

    construct_encrypted_mail(data)
  rescue => e
    log('encryption', 'failed', e.message)
    raise
  end

  def self.encoded_body_part(data)
    Mail::Part.new do
      if data.multipart?
        if data.content_type =~ %r{(multipart[^;]+)}
          # preserve multipart/alternative etc
          content_type $1
        else
          content_type 'multipart/mixed'
        end

        data.body.parts.each do |part|
          add_part SecureMailing::PGP::Outgoing.encoded_body_part(part)
        end
      else
        content_type data.content_type

        if data.content_disposition.present?
          content_disposition data.content_disposition
        end

        if data.header['Content-ID'].present?
          content_id data.header['Content-ID']
        end

        # brute force approach to avoid messed up line endings that break signatures with mail 2.7
        body Base64.encode64(data.body.to_s)
        body.encoding = 'base64'
      end
    end
  end

  private

  def from
    mail.from.first
  end

  def sign_key
    sign_key = PGPKey.find_by_uid(from, secret: true)
    return sign_key if sign_key.present?

    nil
  end

  def construct_signed_mail
    signed_mail = Mail.new(mail)

    signed_mail.body          = nil
    signed_mail.body.preamble = 'This is an OpenPGP/MIME signed message (RFC 3156)' # rubocop:disable Zammad/DetectTranslatableString
    signed_mail.content_type  = "multipart/signed; micalg=pgp-sha1; protocol=\"application/pgp-signature\"; boundary=#{boundary}"

    signed_mail.add_part self.class.encoded_body_part(mail)
    signed_mail.add_part signature_part(signed_mail.encoded)

    signed_mail
  end

  def signature_part(data)
    sign_data = nil
    data.match(%r{boundary="(?<boundary>.+)"}) do |match|
      sign_data = data.split("--#{match['boundary']}")[1..-2].join("\r\n--#{match['boundary']}\r\n").strip
      sign_data = "#{sign_data}\r\n"
    end

    signature = signature(sign_data)

    Mail::Part.new do
      body                signature
      content_type        'application/pgp-signature; name="signature.asc"'
      content_disposition 'attachment; filename="signature.asc"'
      content_description 'OpenPGP digital signature' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  def signature(data)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      pgp_tool.import(sign_key.key)
      result = pgp_tool.sign(data, sign_key.fingerprint, sign_key.passphrase)

      result[:stdout]
    end
  end

  def boundary
    @boundary ||= Mail.random_tag
  end

  def construct_encrypted_mail(data)
    encrypted_mail = Mail.new(data)

    existing_mail_body = existing_mail_body(encrypted_mail)

    encrypted_mail.body          = nil
    encrypted_mail.body.preamble = 'This is an OpenPGP/MIME encrypted message (RFC 3156)' # rubocop:disable Zammad/DetectTranslatableString
    encrypted_mail.content_type  = "multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=#{boundary}"

    encrypted_mail.add_part version_part
    encrypted_mail.add_part encrypted_part(encrypted_body(existing_mail_body))

    encrypted_mail
  end

  def existing_mail_body(encrypted_mail)
    <<~BODY
      Content-Type: #{encrypted_mail.header['Content-Type']}
      Content-Transfer-Encoding: #{encrypted_mail.header['Content-Transfer-Encoding']}

      #{encrypted_mail.body}
    BODY
  end

  def version_part
    Mail::Part.new do
      body                "Version: 1\n" # rubocop:disable Zammad/DetectTranslatableString
      content_type        'application/pgp-encrypted'
      content_description 'PGP/MIME Versions Identification'
    end
  end

  def encrypted_part(data)
    Mail::Part.new do
      body                data
      content_type        'application/octet-stream; name="encrypted.asc"'
      content_disposition 'inline; filename="encrypted.asc"'
      content_description 'OpenPGP encrypted message' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  def encrypted_body(data)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      keys.each { |key| pgp_tool.import(key.key) }
      encrypted_result = pgp_tool.encrypt(data, keys.map(&:fingerprint))

      encrypted_result[:stdout]
    end
  end

  def keys
    keys = []
    %w[to cc].each do |recipient|
      addresses = mail.send(recipient)
      next if !addresses

      keys += PGPKey.for_recipient_email_addresses!(addresses)
    end
    keys
  end
end
