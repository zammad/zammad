# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module HasRoles
  extend ActiveSupport::Concern

  included do
    attr_accessor :reset_notification_config_before_save

    has_and_belongs_to_many :roles,
                            before_add:    %i[validate_agent_limit_by_role validate_roles],
                            after_add:     %i[cache_update role_check_preference_notifications_default],
                            before_remove: :last_admin_check_by_role,
                            after_remove:  %i[cache_update]
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
  def role_access?(group, access)
    return false if !groups_access_permission?

    access = Array(access).map(&:to_sym) | [:full]

    RoleGroup.eager_load(:group, :role).exists?(
      role_id:  roles.pluck(:id),
      group_id: group,
      access:   access,
      groups:   {
        active: true
      },
      roles:    {
        active: true
      }
    )
  end

  def role_check_preference_notifications_default(new_role)
    return true if preferences.dig(:notification_config, :matrix)

    # Check if the new role for the user has "ticket.agent" permission.
    return if new_role.permissions.none? { |permission| permission.name == 'ticket.agent' }

    fill_notification_config_preferences

    self.reset_notification_config_before_save = true
    save if persisted?

    true
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
    def role_access(group, access)
      access = Array(access).map(&:to_sym) | [:full]

      role_ids   = RoleGroup.eager_load(:role).where(group_id: group, access: access, roles: { active: true }).pluck(:role_id)
      join_table = reflect_on_association(:roles).join_table

      Permission.join_with(self, 'ticket.agent').joins(:roles).where(active: true, join_table => { role_id: role_ids }).distinct
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
  end
end
