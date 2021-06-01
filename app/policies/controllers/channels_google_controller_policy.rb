# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ChannelsGoogleControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_google')
end
