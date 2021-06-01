# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::GroupsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.group')
end
