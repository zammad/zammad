class Controllers::ChannelsOffice365ControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_office365')
end
