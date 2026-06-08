# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketArticlesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin')
end
