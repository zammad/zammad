# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CanBeAuthorized
  extend ActiveSupport::Concern

=begin

true or false for permission

  user = User.find(123)
  user.permissions?('permission.key') # access to certain permission.key
  user.permissions?(['permission.key1', 'permission.key2']) # access to permission.key1 or permission.key2

  user.permissions?('permission') # access to all sub keys

  user.permissions?('permission.*') # access if one sub key access exists

returns

  true|false

=end

  def permissions?(auth_query)
    verbatim, wildcards = acceptable_permissions_for(auth_query)

    permissions.where(name: verbatim).then do |base_query|
      wildcards.reduce(base_query) do |query, name|
        query.or(permissions.where('permissions.name LIKE ?', name.sub('.*', '.%')))
      end
    end.exists?
  end

  private

  def acceptable_permissions_for(auth_query)
    Array(auth_query)
      .reject { |name| Permission.lookup(name: name)&.active == false } # See "chain-of-ancestry quirk" in spec file
      .flat_map { |name| Permission.with_parents(name) }.uniq
      .partition { |name| name.end_with?('.*') }.reverse
  end
end
