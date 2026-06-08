# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::GenerateRecoveryCodes < Service::Base
  requires_current_user!

  attr_reader :force

  def initialize(force: false)
    @force = force
  end

  def execute
    return if !current_user.auth_two_factor.recovery_codes_enabled?
    return if current_user.auth_two_factor.user_recovery_codes_exists? && !force

    Auth::TwoFactor::RecoveryCodes.new(current_user).generate
  end
end
