# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('ticket.agent')
end
