# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::UserAccessTokenControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.access_token')
end
