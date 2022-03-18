# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChannelsTelegramControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_telegram')
end
