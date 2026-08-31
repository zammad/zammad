# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::SnipeitControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.snipeit'
  default_permit!(['agent.integration.snipeit', 'admin.integration.snipeit'])
end
