# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::JobsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.scheduler')
end
