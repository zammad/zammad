# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth::TwoFactorConfiguration < Auth::AfterAuth::Backend
  def check
    return false if session[:authentication_type] != 'password'

    user.two_factor_setup_required?
  end
end
