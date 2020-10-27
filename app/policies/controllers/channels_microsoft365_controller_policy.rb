class Controllers::ChannelsMicrosoft365ControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_microsoft365')
end
