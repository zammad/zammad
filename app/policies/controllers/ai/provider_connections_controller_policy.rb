# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AI::ProviderConnectionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.ai_provider')
end
