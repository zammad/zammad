# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::GettingStartedControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :base, to: 'admin.wizard'
end
