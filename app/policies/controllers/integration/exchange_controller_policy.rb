# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Integration::ExchangeControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.integration.exchange')
end
