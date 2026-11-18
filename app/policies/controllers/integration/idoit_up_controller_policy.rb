# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::IdoitUpControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update logo], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.idoit_up'
  default_permit!(['agent.integration.idoit_up', 'admin.integration.idoit_up'])
end
