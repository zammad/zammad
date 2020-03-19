class Controllers::ChannelsEmailControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_email')
end
