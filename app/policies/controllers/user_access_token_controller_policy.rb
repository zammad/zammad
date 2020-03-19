class Controllers::UserAccessTokenControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.access_token')
end
