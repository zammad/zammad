class Controllers::CalendarSubscriptionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.calendar')
end
