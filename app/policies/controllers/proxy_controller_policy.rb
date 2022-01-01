# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ProxyControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.system')
end
