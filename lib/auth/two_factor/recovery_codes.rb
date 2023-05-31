# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::RecoveryCodes < Auth::TwoFactor::Method
  NUMBER_OF_CODES = 10
  CODE_LENGTH = 16

  def verify(code)
    return verify_result(false) if !exists? || code.blank?

    configuration = user_two_factor_preference_configuration

    return verify_result(false) if configuration[:codes].exclude?(code)

    configuration[:codes].delete(code)

    verify_result(true, new_configuration: configuration)
  end

  def generate
    codes = []

    NUMBER_OF_CODES.times do
      # The hex string has length 2*n.
      codes << SecureRandom.hex(CODE_LENGTH / 2)
    end

    if exists?
      update_user_config({ codes: codes })
    else
      create_user_config({ codes: codes })
    end

    codes
  end

  def related_setting_name
    'two_factor_authentication_recovery_codes'
  end

  def exists?
    user_two_factor_preference.present?
  end

  private

  def user_two_factor_preference
    user&.two_factor_preferences&.recovery_codes
  end
end
