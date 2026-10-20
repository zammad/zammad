# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Auth::Permissions
  LEVEL_CUSTOMER = 1
  LEVEL_AGENT    = 2
  LEVEL_ADMIN    = 3

  attr_reader :object, :query

  def initialize(object, query)
    @object = object
    @query = Array(query)
  end

  def self.authorized?(object, query)
    return new(object, query).authorized? if object.id.blank?

    Auth::RequestCache.fetch_value(cache_key(object, query)) do
      new(object, query).authorized?
    end
  end

  # rank of a permission name, used where the permission with the most rights wins
  def self.level(permission)
    case permission
    when %r{^admin\.}   then LEVEL_ADMIN
    when 'ticket.agent' then LEVEL_AGENT
    else                     LEVEL_CUSTOMER
    end
  end

  def self.cache_key(object, query)
    "permissions/#{object.class.name}/#{object.id}_#{Array(query).join('|')}"
  end
  private_class_method :cache_key

  def authorized?
    query.any? do |elem|
      check_single_permission_option(elem)
    end
  end

  private

  def check_single_permission_option(input)
    input
      .split('+')
      .all? do |elem|
        check_single_permission_option_component(elem)
      end
  end

  def check_single_permission_option_component(input)
    if input.exclude?('.')
      return permissions_cache.include?(input)
    end

    # See "chain-of-ancestry quirk" in spec file
    if !input.end_with?('.*') && Permission.lookup(name: input)&.active == false
      return
    end

    Permission
      .with_parents(input)
      .any? do |parent_or_self|
        check_permission_name_in_ancestry_chain(parent_or_self)
      end
  end

  def check_permission_name_in_ancestry_chain(input)
    if input.end_with?('.*')
      permissions_cache.any? { |elem| elem.starts_with?(input.delete_suffix('*')) }
    else
      permissions_cache.include?(input)
    end
  end

  def permissions_cache
    @permissions_cache ||= request_cached_permission_names
  end

  # Shared by all queries for the same user or token, so a new query does not load the names again.
  def request_cached_permission_names
    return permission_names if object.new_record?

    Auth::RequestCache.fetch_value("permission_names/#{object.to_global_id}") { permission_names }
  end

  def permission_names
    object.permissions.pluck(:name)
  end
end
