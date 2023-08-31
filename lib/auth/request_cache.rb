# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class RequestCache < ActiveSupport::CurrentAttributes
    attribute :request_cache

    def self.fetch_value(name)
      self.request_cache ||= {}
      return self.request_cache[name] if !self.request_cache[name].nil?

      self.request_cache[name] = yield
    end

    def self.clear
      self.request_cache = {}
    end

    def self.permissions?(authorizable, auth_query)
      begin
        authorizable_key = authorizable.to_global_id.to_s
      rescue
        return instance.permissions?(authorizable, auth_query)
      end
      auth_query_key = Array(auth_query).join('|')

      fetch_value("permissions/#{authorizable_key}_#{auth_query_key}") do
        instance.permissions?(authorizable, auth_query)
      end
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
