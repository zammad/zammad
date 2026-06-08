# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::User::AdminTwoFactorsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.user')
end
