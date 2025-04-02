# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketPrioritiesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.ticket_priority', 'ticket.customer']
  permit! %i[create update destroy], to: 'admin.ticket_priority'
end
