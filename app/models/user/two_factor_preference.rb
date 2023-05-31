# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorPreference < ApplicationModel
  include HasDefaultModelUserRelations

  belongs_to :user, class_name: 'User', touch: true

  scope :authentication_methods, -> { where.not(method: 'recovery_codes') }
  scope :recovery_codes_methods, -> { where(method: 'recovery_codes') }

  store :configuration

  after_destroy :remove_recovery_codes

  def remove_recovery_codes
    return if method.eql?('recovery_codes')

    current_user_two_factor_preferences = user.two_factor_preferences

    return if current_user_two_factor_preferences.recovery_codes.blank?
    return if current_user_two_factor_preferences.authentication_methods.present?

    current_user_two_factor_preferences.recovery_codes.destroy!
  end
end
