# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorPreference < ApplicationModel
  include HasDefaultModelUserRelations
  include User::TwoFactorPreference::TriggersSubscriptions

  belongs_to :user, class_name: 'User', touch: true

  scope :authentication_methods, -> { where.not(method: 'recovery_codes') }
  scope :recovery_codes_methods, -> { where(method: 'recovery_codes') }

  after_destroy :remove_recovery_codes, :update_user_default
  after_save :update_user_default

  store :configuration

  private

  def remove_recovery_codes
    return if method == 'recovery_codes'
    return if user.two_factor_preferences.authentication_methods.exists?

    user.two_factor_preferences.recovery_codes&.destroy!
  end

  def update_user_default
    return if user.two_factor_preferences.authentication_methods.exists?(method: user.two_factor_default)

    new_default = user.auth_two_factor.user_authentication_methods.first&.method_name

    return if new_default == user.two_factor_default

    if new_default.nil?
      user.preferences[:two_factor_authentication]&.delete :default
    else
      user.preferences[:two_factor_authentication] ||= {}
      user.preferences[:two_factor_authentication][:default] = new_default
    end

    user.save!
  end
end
