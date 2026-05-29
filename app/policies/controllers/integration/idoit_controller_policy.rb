# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::IdoitControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[query update], to: 'integration.idoit'
  permit! :verify, to: 'admin.integration.idoit'
  default_permit!(['integration.idoit', 'admin.integration.idoit'])
end
