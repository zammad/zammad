class Controllers::ChannelsGoogleControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_google')
end
