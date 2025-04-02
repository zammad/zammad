# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::GroupsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.group', 'ticket.customer']
  default_permit!('admin.group')
end
