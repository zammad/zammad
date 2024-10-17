# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::Base < Service::Base
  attr_reader :user, :method_name

  def initialize(user:, method_name:)
    super()

    @user        = user
    @method_name = method_name

    return if method

    raise Exceptions::UnprocessableEntity, __('The given two-factor method does not exist.')
  end

  protected

  def method
    @method ||= user
      .auth_two_factor
      .authentication_method_object(method_name)
  end

  def method_available?
    method&.enabled? && method.available?
  end

  def user_preference
    @user_preference ||= method&.user_two_factor_preference
  end
end
