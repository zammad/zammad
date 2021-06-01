# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::Integration::ExchangeControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.integration.exchange')
end
