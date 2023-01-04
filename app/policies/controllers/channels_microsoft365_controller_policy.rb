# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChannelsMicrosoft365ControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_microsoft365')
end
