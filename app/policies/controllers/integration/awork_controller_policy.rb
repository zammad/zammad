class Controllers::Integration::AworkControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.awork'
  default_permit!(['agent.integration.awork', 'admin.integration.awork'])
end
