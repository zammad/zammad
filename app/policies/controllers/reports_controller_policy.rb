# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ReportsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('report')
end
