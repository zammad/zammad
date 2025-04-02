# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[import_example import_start], to: 'admin'
  permit! %i[ticket_customer ticket_history ticket_related ticket_recent ticket_merge ticket_split], to: 'ticket.agent'
  permit! %i[ticket_create create], to: ['ticket.agent', 'ticket.customer']
end
