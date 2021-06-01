# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ObjectManagerAttributesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.object')
end
