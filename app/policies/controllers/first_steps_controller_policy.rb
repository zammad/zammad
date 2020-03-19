class Controllers::FirstStepsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index test_ticket], to: ['ticket.agent', 'admin']
end
