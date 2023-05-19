# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::Method
  include Mixin::RequiredSubPaths

  attr_reader :user

  def initialize(user = nil)
    @user = user.presence
  end

  # TODO: Add documentation.
  def verify(payload, configuration = user_two_factor_preference_configuration)
    raise NotImplementedError
  end

  def configuration_options
    raise NotImplementedError
  end

  def available?
    true
  end

  def enabled?
    Setting.get(related_setting_name)
  end

  def method_name(human: false)
    return self.class.name.demodulize.underscore if !human

    self.class.name.demodulize.titleize
  end

  def related_setting_name
    "two_factor_authentication_method_#{method_name}"
  end

  def create_user_config(configuration)
    return if configuration.blank?
    return if user_two_factor_preference.present?

    two_factor_prefs = User::TwoFactorPreference.new(
      method:        method_name,
      configuration: configuration,
      user_id:       user.id,
    )
    two_factor_prefs.save!
  end

  def update_user_config(configuration)
    return if configuration.blank?
    return if user_two_factor_preference.blank?

    user_two_factor_preference.update!(configuration: user_two_factor_preference_configuration.merge(configuration))
  end

  def destroy_user_config
    user.two_factor_preferences.find_by(method: method_name)&.destroy
  end

  private

  def user_two_factor_preference
    @user_two_factor_preference ||= user&.two_factor_preferences&.find_by(method: method_name)
  end

  def user_two_factor_preference_configuration
    user_two_factor_preference&.configuration
  end
end
