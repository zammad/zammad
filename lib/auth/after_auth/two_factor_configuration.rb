# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth::TwoFactorConfiguration < Auth::AfterAuth::Backend
  def check
    return false if session[:authentication_type] != 'password'
    return false if !user.two_factor_setup_required?

    issue_password_revalidation_token if options[:initial]

    true
  end

  private

  def issue_password_revalidation_token
    @data[:token] = Token.create(action: 'PasswordCheck', user_id: user.id, persistent: false, expires_at: 1.hour.from_now).token
  end
end
