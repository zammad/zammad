# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::User::TwoFactorsControllerPolicy < Controllers::ApplicationControllerPolicy

  def two_factor_enabled_methods?
    admin_access? || access?
  end

  def two_factor_remove_method?
    admin_access? || access?
  end

  def two_factor_remove_all_methods?
    admin_access? || access?
  end

  def two_factor_verify_configuration?
    true
  end

  def two_factor_method_configuration?
    true
  end

  private

  def admin_access?
    user.permissions?('admin.user')
  end

  def access?
    record.params['id']&.to_i == user.id
  end
end
