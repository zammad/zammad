# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'active_record/migration'

module ActiveRecord
  class Migration
    # migrations create and update records which must not end up in the audit log
    module SuspendsAuditLog
      def migrate(direction)
        AuditLog.suspend { super }
      end
    end

    prepend SuspendsAuditLog
  end
end
