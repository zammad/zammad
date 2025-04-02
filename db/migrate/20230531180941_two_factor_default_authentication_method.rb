# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TwoFactorDefaultAuthenticationMethod < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ::User::TwoFactorPreference.authentication_methods.group_by(&:user_id).each_value do |two_factor_preferences|
      user = two_factor_preferences.first.user

      next if user_has_default_two_factor_authentication_method?(user)

      Service::User::TwoFactor::SetDefaultMethod
        .new(user: user, method_name: two_factor_preferences.first.method, force: true)
        .execute
    end
  end

  private

  def user_has_default_two_factor_authentication_method?(user)
    user.preferences.dig(:two_factor_authentication, :default).present?
  end
end
