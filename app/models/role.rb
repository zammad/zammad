# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Role < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasGroups

  load 'role/assets.rb'
  include Role::Assets

  has_and_belongs_to_many :users, after_add: :cache_update, after_remove: :cache_update
  has_and_belongs_to_many :permissions, after_add: :cache_update, after_remove: :cache_update, before_add: :validate_agent_limit_by_permission, before_remove: :last_admin_check_by_permission
  validates               :name,  presence: true
  store                   :preferences

  before_create  :validate_permissions
  before_update  :validate_permissions, :last_admin_check_by_attribute, :validate_agent_limit_by_attributes

  association_attributes_ignored :users

  activity_stream_permission 'admin.role'

=begin

grant permission to role

  role.permission_grant('permission.key')

=end

  def permission_grant(key)
    permission = Permission.lookup(name: key)
    raise "Invalid permission #{key}" if !permission
    return true if permission_ids.include?(permission.id)
    self.permission_ids = permission_ids.push permission.id
    true
  end

=begin

revoke permission of role

  role.permission_revoke('permission.key')

=end

  def permission_revoke(key)
    permission = Permission.lookup(name: key)
    raise "Invalid permission #{key}" if !permission
    return true if !permission_ids.include?(permission.id)
    self.permission_ids = self.permission_ids -= [permission.id]
    true
  end

=begin

get signup roles

  Role.signup_roles

returns

  [role1, role2, ...]

=end

  def self.signup_roles
    Role.where(active: true, default_at_signup: true)
  end

=begin

get signup role ids

  Role.signup_role_ids

returns

  [role1, role2, ...]

=end

  def self.signup_role_ids
    Role.where(active: true, default_at_signup: true).map(&:id)
  end

=begin

get all roles with permission

  roles = Role.with_permissions('admin.session')

get all roles with permission "admin.session" or "ticket.agent"

  roles = Role.with_permissions(['admin.session', 'ticket.agent'])

returns

  [role1, role2, ...]

=end

  def self.with_permissions(keys)
    permission_ids = Role.permission_ids_by_name(keys)
    Role.joins(:roles_permissions).joins(:permissions).where(
      'permissions_roles.permission_id IN (?) AND roles.active = ? AND permissions.active = ?', permission_ids, true, true
    ).distinct()
  end

=begin

check if roles is with permission

  role = Role.find(123)
  role.with_permission?('admin.session')

get if role has permission of "admin.session" or "ticket.agent"

  role.with_permission?(['admin.session', 'ticket.agent'])

returns

  true | false

=end

  def with_permission?(keys)
    permission_ids = Role.permission_ids_by_name(keys)
    return true if Role.joins(:roles_permissions).joins(:permissions).where(
      'roles.id = ? AND permissions_roles.permission_id IN (?) AND permissions.active = ?', id, permission_ids, true
    ).distinct().count.nonzero?
    false
  end

  private_class_method

  def self.permission_ids_by_name(keys)
    if keys.class != Array
      keys = [keys]
    end
    permission_ids = []
    keys.each do |key|
      ::Permission.with_parents(key).each do |local_key|
        permission = ::Permission.lookup(name: local_key)
        next if !permission
        permission_ids.push permission.id
      end
    end
    permission_ids
  end

  private

  def validate_permissions
    return true if !self.permission_ids
    permission_ids.each do |permission_id|
      permission = Permission.lookup(id: permission_id)
      raise "Unable to find permission for id #{permission_id}" if !permission
      raise "Permission #{permission.name} is disabled" if permission.preferences[:disabled] == true
      next unless permission.preferences[:not]
      permission.preferences[:not].each do |local_permission_name|
        local_permission = Permission.lookup(name: local_permission_name)
        next if !local_permission
        raise "Permission #{permission.name} conflicts with #{local_permission.name}" if permission_ids.include?(local_permission.id)
      end
    end
    true
  end

  def last_admin_check_by_attribute
    return true if !will_save_change_to_attribute?('active')
    return true if active != false
    return true if !with_permission?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableEntity, 'Minimum one user needs to have admin permissions.' if last_admin_check_admin_count < 1
    true
  end

  def last_admin_check_by_permission(permission)
    return true if Setting.get('import_mode')
    return true if permission.name != 'admin' && permission.name != 'admin.user'
    raise Exceptions::UnprocessableEntity, 'Minimum one user needs to have admin permissions.' if last_admin_check_admin_count < 1
    true
  end

  def last_admin_check_admin_count
    admin_role_ids = Role.joins(:permissions).where(permissions: { name: ['admin', 'admin.user'], active: true }, roles: { active: true }).where.not(id: id).pluck(:id)
    User.joins(:roles).where(roles: { id: admin_role_ids }, users: { active: true }).count
  end

  def validate_agent_limit_by_attributes
    return true if !Setting.get('system_agent_limit')
    return true if !will_save_change_to_attribute?('active')
    return true if active != true
    return true if !with_permission?('ticket.agent')
    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    currents = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).pluck(:id)
    news = User.joins(:roles).where(roles: { id: id }, users: { active: true }).pluck(:id)
    count = currents.concat(news).uniq.count
    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit')
    true
  end

  def validate_agent_limit_by_permission(permission)
    return true if !Setting.get('system_agent_limit')
    return true if active != true
    return true if permission.active != true
    return true if permission.name != 'ticket.agent'
    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent' }, roles: { active: true }).pluck(:id)
    ticket_agent_role_ids.push(id)
    count = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).count
    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit')
    true
  end

end
