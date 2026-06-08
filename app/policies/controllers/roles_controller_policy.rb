# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::RolesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.role', 'ticket.customer']
  default_permit!('admin.role')
end
