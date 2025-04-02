# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::User::TwoFactorsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.two_factor_authentication')
end
