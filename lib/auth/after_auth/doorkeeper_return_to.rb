# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Auth::AfterAuth::DoorkeeperReturnTo < Auth::AfterAuth::Backend
  def check
    return false if user&.two_factor_setup_required?

    return_to = session[:doorkeeper_return_to]
    return false if !return_to&.match?(%r{\A/oauth/authorize(/|\?|\z)})

    session.delete(:doorkeeper_return_to)
    @data[:url] = return_to

    true
  end
end
