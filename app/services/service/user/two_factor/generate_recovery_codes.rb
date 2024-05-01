# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::GenerateRecoveryCodes < Service::Base
  attr_reader :user, :force

  def initialize(user:, force: false)
    super()

    @user  = user
    @force = force
  end

  def execute
    return if !user.auth_two_factor.recovery_codes_enabled?
    return if user.auth_two_factor.user_recovery_codes_exists? && !force

    Auth::TwoFactor::RecoveryCodes.new(user).generate
  end
end
