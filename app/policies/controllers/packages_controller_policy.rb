# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::PackagesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.package')
end
