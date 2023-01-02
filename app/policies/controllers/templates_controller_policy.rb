# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TemplatesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.template')
  permit! %i[index show], to: ['admin.template', 'ticket.agent']
end
