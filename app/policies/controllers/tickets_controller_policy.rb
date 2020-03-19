class Controllers::TicketsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[import_example import_start], to: 'admin'
  permit! :selector, to: 'admin.*'
  permit! :create, to: ['ticket.agent', 'ticket.customer']
end
