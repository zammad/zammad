class Controllers::UserDevicesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.device')
end
