# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::SlasControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.sla')
end
