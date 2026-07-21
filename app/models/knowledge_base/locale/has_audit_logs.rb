# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBase::Locale::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  private

  def audit_log_name
    system_locale&.locale
  end
end
