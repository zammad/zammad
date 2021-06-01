# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::Integration::IdoitControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'ticket.agent'
  permit! :verify, to: 'admin.integration.idoit'
  default_permit!(['agent.integration.idoit', 'admin.integration.idoit'])
end
