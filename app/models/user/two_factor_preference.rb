# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class User::TwoFactorPreference < ApplicationModel
  include HasDefaultModelUserRelations

  belongs_to :user, class_name: 'User', touch: true

  scope :authentication_methods, -> { where.not(method: 'recovery_codes') }
  scope :recovery_codes_methods, -> { where(method: 'recovery_codes') }

  after_destroy :remove_recovery_codes, :update_user_preferences
  after_save :update_user_preferences

  store :configuration

  private

  def remove_recovery_codes
    return if method.eql?('recovery_codes')

    current_user_two_factor_preferences = user.two_factor_preferences

    return if current_user_two_factor_preferences.recovery_codes.blank?
    return if current_user_two_factor_preferences.authentication_methods.present?

    current_user_two_factor_preferences.recovery_codes.destroy!
  end

  def update_user_preferences
    count = user.two_factor_preferences.authentication_methods.count
    return true if count > 1

    current_prefs               = user.preferences
    current_pref_default_method = current_prefs.dig(:two_factor_authentication, :default)

    case count
    when 0
      return true if current_pref_default_method.nil?

      current_prefs = remove_default_method_from_preferences(current_prefs)
    when 1
      return true if method_is_default_for_user?(current_pref_default_method)

      current_prefs = add_default_method_to_preferences(current_prefs)
    end

    user.update!(preferences: current_prefs)

    true
  end

  def remove_default_method_from_preferences(preferences)
    preferences[:two_factor_authentication] = preferences[:two_factor_authentication].except(:default)

    preferences
  end

  def add_default_method_to_preferences(preferences)
    preferences[:two_factor_authentication] ||= {}
    preferences[:two_factor_authentication][:default] = first_configured_user_method

    preferences
  end

  def method_is_default_for_user?(method)
    method.present? && first_configured_user_method.eql?(method)
  end

  def first_configured_user_method
    user.two_factor_preferences&.authentication_methods&.first&.method
  end
end
