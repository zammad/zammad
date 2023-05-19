# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth::TwoFactorConfiguration < Auth::AfterAuth::Backend
  def check
    return false if session[:authentication_type].blank?
    return false if !session[:authentication_type].eql?('password')

    user.two_factor_setup_required?
  end
end
