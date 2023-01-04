# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.time_accounting')
end
