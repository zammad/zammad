# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::CalendarsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :timezones, to: 'admin'
  default_permit!('admin.calendar')
end
