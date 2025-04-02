# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::PGPControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :search, to: 'ticket.agent'
  default_permit!('admin.integration.pgp')
end
