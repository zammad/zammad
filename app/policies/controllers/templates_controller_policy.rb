# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TemplatesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(['ticket.agent', 'admin.template'])
end
