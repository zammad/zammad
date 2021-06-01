# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::PackagesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.package')
end
