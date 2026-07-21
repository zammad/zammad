# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBase::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  private

  def audit_log_name
    @audit_log_name ||= translation_primary&.title || translation&.title
  end
end
