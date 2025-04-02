# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::VerifyMethodConfiguration < Service::User::TwoFactor::Base
  attr_reader :payload, :configuration

  def initialize(configuration:, payload:, **)
    super(**)

    @configuration = configuration
    @payload = payload
  end

  def execute
    if !method&.enabled? || !method&.available?
      raise Exceptions::UnprocessableEntity, __('The two-factor authentication method is not enabled.')
    end

    verified = user.two_factor_verify_configuration?(method_name, payload, configuration)

    if !verified
      raise Service::User::TwoFactor::VerifyMethodConfiguration::Failed, __('The verification of the two-factor authentication method configuration failed.')
    end

    {
      recovery_codes: Service::User::TwoFactor::GenerateRecoveryCodes.new(user: user).execute
    }
  end

  class Failed < StandardError; end
end
