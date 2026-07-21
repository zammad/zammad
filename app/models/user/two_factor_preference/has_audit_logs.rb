# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module User::TwoFactorPreference::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  included do
    self.audit_log_name_attribute = :method
    self.audit_log_if = :audit_log_permissions?
  end

  private

  # 2FA changes of customers are not audit logged
  def audit_log_permissions?
    user.permissions?(%w[ticket.agent admin.*])
  end
end
