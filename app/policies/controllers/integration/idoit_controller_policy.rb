# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::IdoitControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.idoit'
  default_permit!(['agent.integration.idoit', 'admin.integration.idoit'])
end
