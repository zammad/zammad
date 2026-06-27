# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Self-hosted ALTCHA proof-of-work CAPTCHA. Challenges are generated and verified
# entirely within Zammad (HMAC-signed with the application secret), so no form data
# leaves the instance — making it the GDPR-friendliest option. (The widget script
# itself is loaded from a CDN, like the other providers' widgets.)
#
# @see https://altcha.org/docs/
class FormSpamProtection::Captcha::Altcha < FormSpamProtection::Captcha
  ALGORITHM      = 'SHA-256'.freeze
  MAX_NUMBER     = 50_000
  CHALLENGE_TTL  = 1.hour
  # Pinned widget version: the server owns ALTCHA verification, so a widget upgrade
  # (payload/protocol change) must be a deliberate, tested change, not picked up silently.
  SCRIPT_URL     = 'https://cdn.jsdelivr.net/npm/altcha@3.1.0/dist/main/altcha.min.js'.freeze
  RESPONSE_FIELD = 'altcha'.freeze

  def self.key
    'altcha'
  end

  def self.title
    'ALTCHA'
  end

  def verify(submission)
    payload = decode_payload(submission.params[RESPONSE_FIELD])
    return false if payload.nil?

    valid_payload?(payload) &&
      !expired?(payload['salt']) &&
      valid_solution?(payload) &&
      valid_signature?(payload['challenge'], payload['signature']) &&
      !replay?(payload['signature'])
  end

  # Builds a signed, time-limited proof-of-work challenge. Served by the challenge
  # endpoint and fetched fresh by the widget on each render, so a solved challenge is
  # never reused.
  def challenge
    salt   = "#{SecureRandom.hex(12)}?expires=#{(Time.zone.now + CHALLENGE_TTL).to_i}"
    number = SecureRandom.random_number(MAX_NUMBER)
    digest = hash_challenge(salt, number)

    {
      algorithm: ALGORITHM,
      challenge: digest,
      maxnumber: MAX_NUMBER,
      salt:,
      signature: sign(digest),
    }
  end

  private

  def widget_config
    {
      type:           'altcha',
      script_url:     SCRIPT_URL,
      module:         true,
      response_field: RESPONSE_FIELD,
      challenge_url:  challenge_url,
    }
  end

  def challenge_url
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/form_captcha_challenge"
  end

  def hash_challenge(salt, number)
    Digest::SHA256.hexdigest("#{salt}#{number}")
  end

  def sign(challenge)
    OpenSSL::HMAC.hexdigest('SHA256', Setting.get('application_secret'), challenge)
  end

  def decode_payload(value)
    return if value.blank?

    JSON.parse(Base64.decode64(value))
  rescue JSON::ParserError, ArgumentError
    Rails.logger.debug 'Form spam protection: rejected submission (malformed ALTCHA payload).'
    nil
  end

  def valid_payload?(payload)
    return true if payload.is_a?(Hash) && payload['algorithm'] == ALGORITHM && payload['salt'].present? && payload['challenge'].present? && payload['signature'].present?

    Rails.logger.debug 'Form spam protection: rejected submission (incomplete ALTCHA payload).'
    false
  end

  def expired?(salt)
    expires = salt.to_s[%r{expires=(\d+)}, 1]
    return false if expires.blank?
    return false if Time.zone.now.to_i <= expires.to_i

    Rails.logger.debug 'Form spam protection: rejected submission (expired ALTCHA challenge).'
    true
  end

  def valid_solution?(payload)
    expected = hash_challenge(payload['salt'], payload['number'])
    return true if ActiveSupport::SecurityUtils.secure_compare(expected, payload['challenge'].to_s)

    Rails.logger.debug 'Form spam protection: rejected submission (invalid ALTCHA solution).'
    false
  end

  def valid_signature?(challenge, signature)
    return true if ActiveSupport::SecurityUtils.secure_compare(sign(challenge), signature.to_s)

    Rails.logger.debug 'Form spam protection: rejected submission (invalid ALTCHA signature).'
    false
  end

  # Each solved challenge may be used only once within its validity window. The
  # write is atomic (unless_exist) so concurrent submissions can't both pass.
  def replay?(signature)
    cache_key = "form_spam_protection/altcha/#{signature}"
    return false if Rails.cache.write(cache_key, true, expires_in: CHALLENGE_TTL, unless_exist: true)

    Rails.logger.debug 'Form spam protection: rejected submission (ALTCHA solution reused).'
    true
  end
end
