# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::ReportProfilesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.report_profile')
end
