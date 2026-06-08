# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AIAgentsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.ai_agent')
end
