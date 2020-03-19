class Controllers::ChannelsTelegramControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_telegram')
end
