# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth::Permissions
  attr_reader :object, :query

  def initialize(object, query)
    @object = object
    @query = Array(query)
  end

  def self.authorized?(object, query)
    Auth::RequestCache.fetch_value(cache_key(object, query)) do
      new(object, query).authorized?
    end
  rescue URI::GID::MissingModelIdError
    new(object, query).authorized?
  end

  def self.cache_key(object, query)
    object_key = object.to_global_id.to_s
    query_key  = Array(query).join('|')

    "permissions/#{object_key}_#{query_key}"
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
    @permissions_cache ||= object.permissions.pluck(:name)
  end
end
