class Controllers::TicketStatesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.object', 'ticket.customer']
  permit! %i[create update destroy], to: 'admin.object'
end
