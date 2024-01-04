# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::DataPrivacyTasksControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.data_privacy')
end
