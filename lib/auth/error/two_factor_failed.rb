# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::Error::TwoFactorFailed < Auth::Error::Base
  MESSAGE = __('Login failed. Please double-check your two-factor authentication method.')

  def message
    MESSAGE
  end
end
