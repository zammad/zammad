class Controllers::Integration::GitHubControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.github'
  default_permit!(['agent.integration.github', 'admin.integration.github'])
end
