# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ApplicationsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.api')
end
