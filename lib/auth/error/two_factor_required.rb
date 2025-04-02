# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Auth::Error::TwoFactorRequired < Auth::Error::Base
  attr_reader :default_two_factor_authentication_method, :available_two_factor_authentication_methods, :recovery_codes_available

  def initialize(auth_user)
    @default_two_factor_authentication_method = auth_user.two_factor.user_default_authentication_method.method_name
    @available_two_factor_authentication_methods = auth_user.two_factor.user_authentication_methods.map(&:method_name)
    @recovery_codes_available = auth_user.two_factor.user_recovery_codes_exists?
    super()
  end
end
