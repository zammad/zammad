# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# HS256 tokens exchanged with the i-doit up add-on. The shared secret is the
# add-on secret stored as `idoit_up_config[:api_token]`.
class IdoitUp
  module Token
    ALGORITHM  = 'HS256'.freeze
    CLOCK_SKEW = 5

    class Error < StandardError; end

    def self.secret
      config = Setting.get('idoit_up_config') || {}
      config[:api_token].presence || config['api_token'].presence || raise(Error, __('The i-doit up add-on secret is not configured.'))
    end

    def self.sign(claims, audience:, ttl: 60, secret: self.secret)
      now     = Time.now.to_i
      header  = encode(JSON.generate({ alg: ALGORITHM, typ: 'JWT' }))
      payload = encode(JSON.generate(claims.merge(aud: audience, iat: now, exp: now + ttl)))
      input   = "#{header}.#{payload}"
      "#{input}.#{encode(hmac(input, secret))}"
    end

    # rubocop:disable-next Zammad/DetectTranslatableString
    def self.verify(token, audience:, secret: self.secret)
      parts = token.to_s.split('.', -1)
      raise Error, 'Malformed token' if parts.size != 3 || parts.any?(&:blank?)

      header, payload, signature = parts
      expected = hmac("#{header}.#{payload}", secret)
      raise Error, 'Invalid signature' if !ActiveSupport::SecurityUtils.secure_compare(decode(signature), expected)
      raise Error, 'Unsupported algorithm' if JSON.parse(decode(header))['alg'] != ALGORITHM

      claims = JSON.parse(decode(payload))
      raise Error, 'Invalid audience' if claims['aud'] != audience
      raise Error, 'Token expired' if !claims['exp'].is_a?(Integer) || claims['exp'] + CLOCK_SKEW < Time.now.to_i
      raise Error, 'Missing subject' if claims['sub'].blank?

      claims
    rescue JSON::ParserError, ArgumentError
      raise Error, 'Malformed token'
    end

    def self.encode(value)
      Base64.urlsafe_encode64(value, padding: false)
    end

    def self.decode(value)
      Base64.urlsafe_decode64(value)
    end

    def self.hmac(input, secret)
      OpenSSL::HMAC.digest('SHA256', secret, input)
    end
  end
end
