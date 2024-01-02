# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::GroupsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.group')
end
