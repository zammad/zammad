# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::TriggersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.trigger')
end
