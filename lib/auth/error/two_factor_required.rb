# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::Error::TwoFactorRequired < Auth::Error::Base
  attr_reader :default_two_factor_method, :available_two_factor_methods

  def initialize(auth_user)
    @default_two_factor_method = auth_user.two_factor.user_default_method.method_name
    @available_two_factor_methods = auth_user.two_factor.user_methods.map(&:method_name)
    super()
  end
end
