# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    RequestCache.permissions?(self, auth_query)
  end

  class RequestCache < ActiveSupport::CurrentAttributes
    attribute :permission_cache

    def self.permissions?(authorizable, auth_query)
      self.permission_cache ||= {}

      begin
        authorizable_key = authorizable.to_global_id.to_s
      rescue
        return instance.permissions?(authorizable, auth_query)
      end
      auth_query_key = Array(auth_query).join('|')

      self.permission_cache[authorizable_key] ||= {}
      self.permission_cache[authorizable_key][auth_query_key] ||= instance.permissions?(authorizable, auth_query)
    end

    def permissions?(authorizable, auth_query)
      verbatim, wildcards = acceptable_permissions_for(auth_query)

      authorizable.permissions.where(name: verbatim).then do |base_query|
        wildcards.reduce(base_query) do |query, name|
          query.or(authorizable.permissions.where('permissions.name LIKE ?', name.sub('.*', '.%')))
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
end
