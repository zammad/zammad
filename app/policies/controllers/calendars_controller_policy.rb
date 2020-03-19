class Controllers::CalendarsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :timezones, to: 'admin'
  default_permit!('admin.calendar')
end
