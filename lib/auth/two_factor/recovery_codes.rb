# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::RecoveryCodes < Auth::TwoFactor::Method
  NUMBER_OF_CODES = 10
  CODE_LENGTH = 16

  def verify(code)
    return verify_result(false) if !exists? || code.blank?

    configuration = user_two_factor_preference_configuration

    hashed_code = configuration[:codes].detect { |saved_code| PasswordHash.verified?(saved_code, code) }
    return verify_result(false) if hashed_code.blank?

    configuration[:codes].delete(hashed_code)

    verify_result(true, new_configuration: configuration)
  end

  def generate
    codes = []

    NUMBER_OF_CODES.times do
      # The hex string has length 2*n.
      codes << SecureRandom.hex(CODE_LENGTH / 2)
    end

    hashed_codes = codes.map { |code| PasswordHash.crypt(code) }

    create_user_config({ codes: hashed_codes })

    codes
  end

  def related_setting_name
    'two_factor_authentication_recovery_codes'
  end

  def exists?
    user_two_factor_preference.present?
  end

  def user_two_factor_preference
    user&.two_factor_preferences&.recovery_codes
  end
end
