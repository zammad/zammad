# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ChatSessionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('chat.agent')
end
