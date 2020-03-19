class Controllers::PostmasterFiltersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_email')
end
