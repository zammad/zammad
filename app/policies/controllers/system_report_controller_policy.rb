# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::SystemReportControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.system_report')
end
