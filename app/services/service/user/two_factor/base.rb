# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::Base < Service::Base
  requires_current_user!

  attr_reader :method_name

  def initialize(method_name:)
    @method_name = method_name

    return if method

    raise Exceptions::UnprocessableContent, __('The given two-factor method does not exist.')
  end

  protected

  def method
    @method ||= current_user
      .auth_two_factor
      .authentication_method_object(method_name)
  end

  def method_available?
    method&.enabled? && method.available?
  end

  def user_preference
    return if !client_safe_config?

    @user_preference ||= method&.user_two_factor_preference
  end

  def client_safe_config?
    !method.without_client_config?
  end
end
