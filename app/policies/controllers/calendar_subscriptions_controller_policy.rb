# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::CalendarSubscriptionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.calendar')
end
