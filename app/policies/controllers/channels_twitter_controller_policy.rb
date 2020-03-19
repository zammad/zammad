class Controllers::ChannelsTwitterControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_twitter')
end
