# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Provide the internal id only for objects that need it, for example
#   in URLs.
module Gql::Types::Concerns::HasPunditAuthorization
  extend ActiveSupport::Concern

  class_methods do
    # Add default object authorization via Pundit.
    def authorized?(object, ctx)
      Pundit.authorize ctx.current_user, pundit_object(object), pundit_method(ctx)
    rescue Pundit::NotAuthorizedError
      raise(Exceptions::Forbidden, "Access forbidden by #{name}")
    end

    # Override this method in object types
    #   to use e.g. a specific attribute (like a parent object) to check for access.
    def pundit_object(object)
      object
    end

    # Authorize depending on direct access to the field or nested access via
    #   previously authorized parent object.
    def pundit_method(ctx)
      ctx[:is_dependent_field] ? nested_access_pundit_method : direct_access_pundit_method
    end

    # Override this in object types to use different methods.
    def nested_access_pundit_method
      :show?
    end

    # Override this in object types to use different methods.
    def direct_access_pundit_method
      :show?
    end
  end

  # Only authorize object once, and then memoize the result (e.g. for fields
  #   on the same object).
  def cached_pundit_authorize
    method = self.class.pundit_method(context)
    @pundit_cache ||= {}
    return @pundit_cache[method] if @pundit_cache.key?(method)

    @pundit_cache[method] = begin
      # Invoke policy directly to get back the actual result,
      #   not the original object as returned by 'authorize'.
      Pundit.policy(context.current_user, object).public_send(method)
    rescue Pundit::NotAuthorizedError
      false
    end
  end
end
