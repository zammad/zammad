# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::Error::AuthenticationFailed < Auth::Error::Base
  MESSAGE = __('Login failed. Have you double-checked your credentials and completed the email verification step?')

  def message
    MESSAGE
  end
end
