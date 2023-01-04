# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChatsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.channel_chat')
end
