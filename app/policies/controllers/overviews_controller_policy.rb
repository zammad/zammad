# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::OverviewsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.overview')
end
