# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('ticket.agent')
end
