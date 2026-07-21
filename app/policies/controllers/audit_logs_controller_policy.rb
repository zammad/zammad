# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::AuditLogsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.audit_log')
end
