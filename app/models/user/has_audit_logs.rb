# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# audit logging for users, tracking only password, role and group permission changes
# and merging all changes of an update into a single entry
module User::HasAuditLogs
  extend ActiveSupport::Concern

  include ::HasAuditLogs

  included do
    self.audit_log_name_attribute = :fullname
    self.audit_log_attributes_tracked = %i[password active]
    self.audit_log_if = :audit_log_permissions?

    # remember the associations before the roles and group permissions are removed along with the user
    before_destroy :audit_log_remember_associations, prepend: true
  end

  private

  # changes of customers are not audit logged - the permissions of a
  # destroyed user are captured before its roles are removed
  def audit_log_permissions?
    return @audit_log_destroy_snapshot.present? if destroyed?

    permissions?(%w[ticket.agent admin.*])
  end

  def audit_log_destroy
    return if @audit_log_destroy_snapshot.blank?

    audit_log_add('destroy', @audit_log_destroy_snapshot, {})
  end

  def audit_log_remember_associations
    return if !audit_log_permissions?

    snapshot = {}

    role_names = roles.filter_map { |role| role.name if role.grants_elevated_access? }
    snapshot['roles'] = role_names if role_names.present?

    group_permissions = audit_log_group_permissions.each_with_object({}) do |(group_name, access), map|
      (map[group_name] ||= []).push(access)
    end
    snapshot['group_permissions'] = group_permissions if group_permissions.present?

    @audit_log_destroy_snapshot = snapshot
  end

  # attribute updates are buffered and merged with role and group permission
  # changes of the same transaction into a single update entry
  def audit_log_add(action_type, value_from, value_to, preferences = {})
    return super if action_type != 'update'

    AuditLog.log_attribute_update(record: self, value_from: value_from, value_to: value_to, changed_attributes: preferences[:changed_attributes])
  end

  # group permissions are part of the create entry of a new user
  # and logged as added/removed changes of the update entry otherwise
  def process_group_access_buffer
    return super if group_access_buffer.nil?

    value_before = audit_log_group_permissions
    super
    value_after = audit_log_group_permissions

    action_type = audit_log_creating? ? 'create' : 'update'

    (value_after - value_before).each do |group_name, access|
      AuditLog.log_association_update(record: self, action_type: action_type, key: ['group_permissions', group_name], added: access, allow_create: true)
    end

    (value_before - value_after).each do |group_name, access|
      AuditLog.log_association_update(record: self, action_type: action_type, key: ['group_permissions', group_name], removed: access, allow_create: true)
    end
  end

  def audit_log_group_permissions
    UserGroup.where(user_id: id).joins(:group).pluck('groups.name', :access)
  end
end
