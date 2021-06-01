# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::RolesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.role')
end
