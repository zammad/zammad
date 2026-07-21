# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# audit logging for roles, adding the selected permissions and group permissions
# to the create and destroy snapshots and merging all changes of an update into a single entry
module Role::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  included do
    # remember the associations before the dependent records are destroyed along with the role
    before_destroy :audit_log_remember_associations, prepend: true
  end

  private

  def audit_log_create
    audit_log_add('create', {}, audit_log_snapshot(attributes).merge(audit_log_creation_associations))
  end

  # attribute updates are buffered and merged with permission and group permission
  # changes of the same transaction into a single update entry
  def audit_log_add(action_type, value_from, value_to, preferences = {})
    return super if action_type != 'update'

    AuditLog.log_attribute_update(record: self, value_from: value_from, value_to: value_to, changed_attributes: preferences[:changed_attributes])
  end

  def audit_log_destroy
    audit_log_add('destroy', audit_log_snapshot(attributes).merge(@audit_log_destroy_associations || {}), {})
  end

  def audit_log_remember_associations
    @audit_log_destroy_associations = {}

    permission_names = permissions.map(&:name)
    @audit_log_destroy_associations['permissions'] = permission_names if permission_names.present?

    group_permissions = audit_log_persisted_group_permissions
    @audit_log_destroy_associations['group_permissions'] = group_permissions if group_permissions.present?
  end

  def audit_log_persisted_group_permissions
    RoleGroup.where(role_id: id).joins(:group).pluck('groups.name', :access).each_with_object({}) do |(group_name, access), map|
      (map[group_name] ||= []).push(access)
    end
  end

  # permissions and group accesses of a new role are only assigned in memory
  # when the create entry is written, so they are read from there
  def audit_log_creation_associations
    associations = {}

    associations['permissions'] = permissions.map(&:name) if permissions.loaded? && permissions.present?

    group_permissions = audit_log_creation_group_permissions
    associations['group_permissions'] = group_permissions if group_permissions.present?

    associations
  end

  def audit_log_creation_group_permissions
    entries = Array.wrap(group_access_buffer)
    return {} if entries.blank?

    group_names = Group.where(id: entries.pluck(:group_id)).pluck(:id, :name).to_h

    entries.each_with_object({}) do |entry, map|
      group_name = group_names[entry[:group_id].to_i] || entry[:group_id]

      (map[group_name] ||= []).push(entry[:access])
    end
  end

  # group permissions of a new role are already part of the create entry, suppress their update entries
  def process_group_access_buffer
    return super if !audit_log_creating?

    AuditLog.suspend { super }
  end
end
