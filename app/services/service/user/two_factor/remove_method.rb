# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::RemoveMethod < Service::User::TwoFactor::Base
  def execute
    method.destroy_user_config
  end
end
