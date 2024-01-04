# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChannelsGoogleControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_google')
end
