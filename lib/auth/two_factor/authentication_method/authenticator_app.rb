# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::AuthenticationMethod::AuthenticatorApp < Auth::TwoFactor::AuthenticationMethod
  ORDER = 2000

  def verify(payload, configuration = user_two_factor_preference_configuration)
    return verify_result(false) if payload.blank? || configuration.blank?

    secret = configuration[:secret]
    return verify_result(false) if secret.blank?

    last_otp_at = configuration[:last_otp_at]

    timestamp = totp(secret).verify(payload, drift_behind: 15, after: last_otp_at)

    # The provided code is invalid if we don't get a timestamp value.
    return verify_result(false) if timestamp.blank?

    # Return new configuration hash with the updated timestamp.
    verify_result(true, configuration: configuration, new_configuration: { last_otp_at: timestamp })
  end

  def initiate_configuration
    require 'rotp' # Only load when it is actually used
    secret = ROTP::Base32.random_base32

    {
      secret:           secret,
      provisioning_uri: totp(secret).provisioning_uri(user.login),
    }
  end

  private

  def issuer
    Setting.get('organization').presence || Setting.get('product_name').presence || 'Zammad'
  end

  def totp(secret)
    require 'rotp' # Only load when it is actually used
    ROTP::TOTP.new(secret, issuer: issuer)
  end
end
