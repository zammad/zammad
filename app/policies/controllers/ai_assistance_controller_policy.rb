# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AIAssistanceControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('ticket.agent')
end
