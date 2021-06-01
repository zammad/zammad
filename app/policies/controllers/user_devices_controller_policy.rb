# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::UserDevicesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.device')
end
