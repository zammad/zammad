# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesAuthorization
  extend ActiveSupport::Concern

  included do
    class_attribute :required_permissions, default: []
    class_attribute :require_authentication, default: true

    #
    # Custom static authorization handling.
    #
    class << self
      def authorize(obj, ctx)
        # Public queries override this to allow unauthenticated access.
        return true if !evaluate_require_authentication(ctx, obj)

        validate_user(ctx, obj) && validate_permissions(ctx, obj)
      end

      #
      # Internal methods
      #

      # This method is used by GraphQL to perform authorization on the various objects.
      # This may be called with 2 or 3 params, context is last.
      def authorized?(*)
        begin
          authorize(*)
        rescue Pundit::NotAuthorizedError # Some old code may raise this instead of returning false
          false
        end || raise(Exceptions::Forbidden, "Access forbidden by #{name}")
      end
    end

    #
    # Dynamic authorization handling.
    #

    # Helper method to check pundit authorization of the current user for a given object.
    def pundit_authorize!(record, query = :show?)
      Pundit.authorize(context.current_user, record, query)
    end

    # Helper method to check pundit authorization of the current user for a given object.
    def pundit_authorized?(record, query = :show?)
      # Invoke policy directly to get back the actual result,
      #   not the original object as returned by 'authorize'.
      Pundit.policy(context.current_user, record).public_send(query)
    end
  end

  class_methods do
    def requires_permission(*permissions)
      self.required_permissions = permissions
    end

    def requires_authentication(value)
      self.require_authentication = value
    end

    def allow_public_access!
      self.require_authentication = false
    end

    def evaluate_require_authentication(ctx, obj)
      if require_authentication.is_a?(Proc)
        return require_authentication.call(ctx, obj)
      end

      !!require_authentication
    end

    def validate_user(ctx, _obj)
      # throws Exceptions::NotAuthorized if not authorized
      ctx.current_user
    end

    def validate_permissions(ctx, _obj)
      return true if required_permissions.blank?

      ctx.current_user.permissions?(required_permissions)
    end
  end
end
