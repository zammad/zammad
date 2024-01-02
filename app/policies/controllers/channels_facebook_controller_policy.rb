# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChannelsFacebookControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_facebook')
end
