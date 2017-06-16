# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Role < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasGroups

  load 'role/assets.rb'
  include Role::Assets

  has_and_belongs_to_many :users, after_add: :cache_update, after_remove: :cache_update
  has_and_belongs_to_many :permissions, after_add: :cache_update, after_remove: :cache_update, before_add: :validate_agent_limit
  validates               :name,  presence: true
  store                   :preferences

  before_create  :validate_permissions
  before_update  :validate_permissions

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
    if keys.class != Array
      keys = [keys]
    end
    roles = []
    permission_ids = []
    keys.each { |key|
      Object.const_get('Permission').with_parents(key).each { |local_key|
        permission = Object.const_get('Permission').lookup(name: local_key)
        next if !permission
        permission_ids.push permission.id
      }
      next if permission_ids.empty?
      Role.joins(:roles_permissions).joins(:permissions).where('permissions_roles.permission_id IN (?) AND roles.active = ? AND permissions.active = ?', permission_ids, true, true).uniq().each { |role|
        roles.push role
      }
    }
    return [] if roles.empty?
    roles
  end

  private

  def validate_permissions
    return true if !self.permission_ids
    permission_ids.each { |permission_id|
      permission = Permission.lookup(id: permission_id)
      raise "Unable to find permission for id #{permission_id}" if !permission
      raise "Permission #{permission.name} is disabled" if permission.preferences[:disabled] == true
      next unless permission.preferences[:not]
      permission.preferences[:not].each { |local_permission_name|
        local_permission = Permission.lookup(name: local_permission_name)
        next if !local_permission
        raise "Permission #{permission.name} conflicts with #{local_permission.name}" if permission_ids.include?(local_permission.id)
      }
    }
    true
  end

  def validate_agent_limit(permission)
    return true if !Setting.get('system_agent_limit')
    return true if permission.name != 'ticket.agent'

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent' }).pluck(:id)
    ticket_agent_role_ids.push(id)
    count = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).count

    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit')
    true
  end

end
