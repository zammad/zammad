# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasRoles
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :roles,
                            before_add:    %i[validate_agent_limit_by_role validate_roles],
                            after_add:     %i[cache_update check_notifications push_ticket_create_screen_for_role_change],
                            before_remove: :last_admin_check_by_role,
                            after_remove:  %i[cache_update push_ticket_create_screen_for_role_change]
  end

  # Checks a given Group( ID) for given access(es) for the instance associated roles.
  #
  # @example Group ID param
  #   user.role_access?(1, 'read')
  #   #=> true
  #
  # @example Group param
  #   user.role_access?(group, 'read')
  #   #=> true
  #
  # @example Access list
  #   user.role_access?(group, ['read', 'create'])
  #   #=> true
  #
  # @return [Boolean]
  def role_access?(group_id, access)
    return false if !groups_access_permission?

    group_id = self.class.ensure_group_id_parameter(group_id)
    access   = self.class.ensure_group_access_list_parameter(access)

    RoleGroup.eager_load(:group, :role).exists?(
      role_id:  roles.pluck(:id),
      group_id: group_id,
      access:   access,
      groups:   {
        active: true
      },
      roles:    {
        active: true
      }
    )
  end

  def push_ticket_create_screen_for_role_change(role)
    return if Setting.get('import_mode')

    permission = Permission.lookup(name: 'ticket.agent')
    return if !role.permissions.exists?(id: permission.id)

    push_ticket_create_screen_background_job
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    # Lists instances having the given access(es) to the given Group through Roles.
    #
    # @example Group ID param
    #   User.role_access(1, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Group param
    #   User.role_access(group, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Access list
    #   User.role_access(group, ['read', 'create'])
    #   #=> [1, 3, ...]
    #
    # @return [Array<Integer>]
    def role_access(group_id, access)
      group_id = ensure_group_id_parameter(group_id)
      access   = ensure_group_access_list_parameter(access)

      role_ids   = RoleGroup.eager_load(:role).where(group_id: group_id, access: access, roles: { active: true }).pluck(:role_id)
      join_table = reflect_on_association(:roles).join_table
      joins(:roles).where(active: true, join_table => { role_id: role_ids }).distinct.select(&:groups_access_permission?)
    end

    # Lists IDs of instances having the given access(es) to the given Group through Roles.
    #
    # @example Group ID param
    #   User.role_access_ids(1, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Group param
    #   User.role_access_ids(group, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Access list
    #   User.role_access_ids(group, ['read', 'create'])
    #   #=> [1, 3, ...]
    #
    # @return [Array<Integer>]
    def role_access_ids(group_id, access)
      role_access(group_id, access).collect(&:id)
    end

    def ensure_group_id_parameter(group_or_id)
      return group_or_id if group_or_id.is_a?(Integer)

      group_or_id.id
    end

    def ensure_group_access_list_parameter(access)
      access = [access] if access.is_a?(String)
      access.push('full') if access.exclude?('full')
      access
    end
  end
end
