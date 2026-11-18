# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ContentTranslation::ProvidersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(%w[admin.integration admin.ai_assistance_translation])
end
