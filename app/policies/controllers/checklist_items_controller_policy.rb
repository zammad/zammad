# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChecklistItemsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(['ticket.agent'])
end
