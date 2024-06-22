# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module User::Permissions
  extend ActiveSupport::Concern

  included do
    has_many :permissions, -> { where(roles: { active: true }, active: true) }, through: :roles

    association_attributes_ignored :permissions

    # Gets all users with the given permission names
    # @param permission_names [Array<String>] list of permission_names
    # @example
    #   User.with_permissions('ticket.agent', 'admin')
    # @return [Array<User>]
    scope :with_permissions, lambda { |*permission_names|
      permission_names.flatten!

      role_ids = Role.with_permissions(permission_names)

      return none if role_ids.blank?

      joins(:roles_users)
        .where(users: { active: true }, roles_users: { role_id: role_ids })
        .distinct
        .reorder(:id)
    }
  end

=begin

returns all accessable permission ids of user

  user = User.find(123)
  user.permissions_with_child_ids

returns

  [permission1_id, permission2_id, permission3_id]

=end

  def permissions_with_child_ids
    permissions_with_child_elements.pluck(:id)
  end

=begin

returns all accessable permission names of user

  user = User.find(123)
  user.permissions_with_child_names

returns

  [permission1_name, permission2_name, permission3_name]

=end

  def permissions_with_child_names
    permissions_with_child_elements.pluck(:name)
  end

  def permissions?(query)
    Auth::Permissions.authorized?(self, query)
  end

  def permissions!(query)
    return true if permissions?(query)

    raise Exceptions::Forbidden, __('User authorization failed.')
  end

  def permissions_with_child_and_parent_elements
    permission_names         = permissions.pluck(:name)
    names_including_ancestor = permission_names.flat_map { |name| Permission.with_parents(name) }.uniq

    base_query = Permission.reorder(:name).where(active: true)

    permission_names
      .reduce(base_query.where(name: names_including_ancestor)) do |memo, name|
        memo.or(base_query.where('permissions.name LIKE ?', "#{SqlHelper.quote_like(name)}.%"))
      end
      .tap do |permissions|
        ancestor_names = names_including_ancestor - permission_names

        permissions
          .select { |permission| permission.name.in?(ancestor_names) }
          .each { |permission| permission.preferences['disabled'] = true }
      end
  end

  private

  def permissions_with_child_elements
    where = ''
    where_bind = [true]
    permissions.pluck(:name).each do |permission_name|
      where += ' OR ' if where != ''
      where += 'permissions.name = ? OR permissions.name LIKE ?'
      where_bind.push permission_name
      where_bind.push "#{SqlHelper.quote_like(permission_name)}.%"
    end
    return [] if where == ''

    ::Permission.where("permissions.active = ? AND (#{where})", *where_bind)
  end
end
