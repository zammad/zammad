# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Setting::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  included do
    self.audit_log_attributes_ignored = %i[preferences]
  end

  private

  # sensitive settings are tracked in the audit log, but their values are masked
  def audit_log_mask(snapshot)
    return snapshot if !sensitive?

    SensitiveParamsHelper.new(%w[state_current.value state_initial.value]).mask(snapshot)
  end
end
