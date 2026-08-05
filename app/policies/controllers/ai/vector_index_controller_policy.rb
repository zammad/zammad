# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AI::VectorIndexControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(%w[admin.ai_knowledge_base admin.ai_provider])
end
