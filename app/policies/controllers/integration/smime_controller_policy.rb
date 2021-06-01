# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::Integration::SMIMEControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :search, to: 'ticket.agent'
  default_permit!('admin.integration.smime')
end
