# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::TemplatesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(['ticket.agent', 'admin.template'])
end
