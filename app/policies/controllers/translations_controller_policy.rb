# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TranslationsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.translation')
end
