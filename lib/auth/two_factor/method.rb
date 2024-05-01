# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::Method
  attr_reader :user

  def initialize(user = nil)
    @user = user.presence
  end

  def verify(payload)
    raise NotImplementedError
  end

  def enabled?
    @enabled ||= Setting.get(related_setting_name)
  end

  def method_name(human: false)
    return self.class.name.demodulize.underscore if !human

    self.class.name.demodulize.titleize
  end

  def create_user_config(configuration)
    return if configuration.blank?
    return update_user_config(configuration) if user_two_factor_preference.present?

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
    user.two_factor_preferences.find_by(method: method_name)&.destroy!
  end

  def user_two_factor_preference
    raise NotImplementedError
  end

  def user_two_factor_preference_configuration
    user_two_factor_preference&.configuration
  end

  private

  def verify_result(verified, configuration: {}, new_configuration: {})
    return { verified: false } if !verified

    {
      **configuration,
      verified: true,
      **new_configuration,
    }
  end

  def related_setting_name
    raise NotImplementedError
  end
end
