# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::User::TwoFactorsControllerPolicy < Controllers::ApplicationControllerPolicy

  def two_factor_enabled_authentication_methods?
    admin_access? || access?
  end

  def two_factor_remove_authentication_method?
    admin_access? || access?
  end

  def two_factor_remove_all_authentication_methods?
    admin_access? || access?
  end

  def two_factor_personal_configuration?
    true
  end

  def two_factor_verify_configuration?
    true
  end

  def two_factor_recovery_codes_generate?
    true
  end

  def two_factor_default_authentication_method?
    true
  end

  def two_factor_authentication_method_initiate_configuration?
    true
  end

  def two_factor_authentication_method_configuration?
    true
  end

  def two_factor_authentication_remove_credentials?
    true
  end

  private

  def admin_access?
    user.permissions?('admin.user')
  end

  def access?
    return false if record.params['id']&.to_i != user.id

    user.permissions?('user_preferences.two_factor_authentication')
  end
end
