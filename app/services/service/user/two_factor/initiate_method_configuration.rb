# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::InitiateMethodConfiguration < Service::User::TwoFactor::Base
  def execute
    if !method_available?
      raise Exceptions::UnprocessableContent, __('The two-factor authentication method is not enabled.')
    end

    method.initiate_configuration
  end
end
