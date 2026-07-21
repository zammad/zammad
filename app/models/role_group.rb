# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RoleGroup < ApplicationModel
  include HasGroupRelationDefinition

  self.table_name = 'roles_groups'

  # don't list roles in Group association result
  Group.association_attributes_ignored :roles

  after_create  :audit_log_group_permission_add
  after_destroy :audit_log_group_permission_remove

  private

  def audit_log_group_permission_add
    return if role.blank? || group.blank?

    AuditLog.log_association_update(record: role, action_type: 'update', key: ['group_permissions', group.name], added: access)
  end

  def audit_log_group_permission_remove
    return if role.blank? || group.blank?

    AuditLog.log_association_update(record: role, action_type: 'update', key: ['group_permissions', group.name], removed: access)
  end
end
