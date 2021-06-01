# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ReportsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('report')
end
