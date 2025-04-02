# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::SetDefaultMethod < Service::User::TwoFactor::Base
  attr_reader :force

  def initialize(force: false, **)
    super(**)

    @force = force
  end

  def execute
    if !method_available? && !force
      raise Exceptions::UnprocessableEntity, __('The given two-factor authentication method is not enabled.')
    end

    if !method_configured? && !force
      raise Exceptions::UnprocessableEntity, __('The given two-factor authentication method is not configured.')
    end

    update_user_preferences!
  end

  private

  def method_configured?
    user
      .auth_two_factor
      .user_authentication_methods
      .find { |elem| elem.method_name == method_name }
  end

  def update_user_preferences!
    user.preferences[:two_factor_authentication] ||= {}
    user.preferences[:two_factor_authentication][:default] = method_name

    user.save!
  end
end
