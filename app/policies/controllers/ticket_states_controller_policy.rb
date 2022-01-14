# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketStatesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.object', 'ticket.customer']
  permit! %i[create update destroy], to: 'admin.object'
end
