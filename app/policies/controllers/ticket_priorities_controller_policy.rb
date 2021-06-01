# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::TicketPrioritiesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.object', 'ticket.customer']
  permit! %i[create update destroy], to: 'admin.object'
end
