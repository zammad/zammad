# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AITextToolsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.ai_assistance_text_tools')
end
