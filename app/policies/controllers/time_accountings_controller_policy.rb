# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.time_accounting')
end
