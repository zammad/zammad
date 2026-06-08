# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::GettingStartedControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :base, to: 'admin.wizard'
end
