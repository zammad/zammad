# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::MacrosControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit! ['admin.macro']

  permit! %i[index show], to: ['ticket.agent']
end
