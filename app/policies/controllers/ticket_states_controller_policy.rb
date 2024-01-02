# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketStatesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.ticket_state', 'ticket.customer']
  permit! %i[create update destroy], to: 'admin.ticket_state'
end
