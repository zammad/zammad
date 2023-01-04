# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MacrosControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit! ['admin.macro']

  permit! %i[index show], to: ['admin.macro', 'ticket.agent']
end
