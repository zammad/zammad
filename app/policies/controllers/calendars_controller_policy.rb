# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::CalendarsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :timezones, to: ['admin.calendar', 'admin.trigger', 'admin.scheduler']
  default_permit!('admin.calendar')
end
