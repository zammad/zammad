# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor::AuthenticationMethod < Auth::TwoFactor::Method
  include Mixin::RequiredSubPaths

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

  def related_setting_name
    "two_factor_authentication_method_#{method_name}"
  end

  private

  def user_two_factor_preference
    user&.two_factor_preferences&.authentication_methods&.find_by(method: method_name)
  end
end
