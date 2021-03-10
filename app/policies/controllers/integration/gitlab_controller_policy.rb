class Controllers::Integration::GitLabControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.gitlab'
  default_permit!(['agent.integration.gitlab', 'admin.integration.gitlab'])
end
