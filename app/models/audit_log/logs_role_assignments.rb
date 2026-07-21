# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module AuditLog::LogsRoleAssignments
  extend ActiveSupport::Concern

  module ClassMethods
=begin

log the assignment or removal of an agent/admin related role to/from a user

  AuditLog.log_role_assignment(user: user, role: role, action_type: 'role_add')
  AuditLog.log_role_assignment(user: user, role: role, action_type: 'role_remove')

no entry is created for roles that do not grant agent or admin access (e.g. the customer role)

unlike other association updates this is also logged while the user is being created,
so that new users receiving agent or admin access right away show up in the audit log -
in this case as part of the create entry instead of an update entry

=end

    def log_role_assignment(user:, role:, action_type:)
      return if !role.grants_elevated_access?

      added, removed = action_type == 'role_add' ? [role.name, nil] : [nil, role.name]

      entry_action_type = user.audit_log_creating? ? 'create' : 'update'

      log_association_update(record: user, action_type: entry_action_type, key: 'roles', added: added, removed: removed, allow_create: true)
    end
  end
end
