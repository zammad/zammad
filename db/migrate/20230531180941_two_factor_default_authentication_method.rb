# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TwoFactorDefaultAuthenticationMethod < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ::User::TwoFactorPreference.authentication_methods.group_by(&:user_id).each do |_user_id, two_factor_preferences|
      user = two_factor_preferences.first.user

      next if user_has_default_two_factor_authentication_method?(user)

      user.two_factor_update_default_method(two_factor_preferences.first.method)
    end
  end

  private

  def user_has_default_two_factor_authentication_method?(user)
    user.auth_two_factor.user_default_authentication_method.present?
  end
end
