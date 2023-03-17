# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChatSessionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('chat.agent')
end
