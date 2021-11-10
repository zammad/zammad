# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Concern::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    #
    # Customizable methods
    #

    # Override this method to specify if an object needs CSRF verification.
    def self.requires_csrf_verification?
      false # No check required by default, only by mutations.
    end

    # Override this method to specify if an object needs an authenticated user.
    def self.requires_authentication?
      true # Authentication required by default for everything.
    end

    # Override this method if an object requires custom authorization, e.g. based on Pundit.
    def self.authorize(...)
      true # Authorization is granted by default.
    end

    #
    # Internal methods
    #

    # This method is used by GraphQL to perform authorization on the various objects.
    def self.authorized?(*args)
      ctx = args[-1] # This may be called with 2 or 3 params, context is last.

      # CSRF
      verify_csrf_token(ctx) if requires_csrf_verification?

      # Authenticate
      if requires_authentication? && !ctx[:current_user]
        # This exception actually means 'NotAuthenticated'
        raise Exceptions::NotAuthorized, "Authentication required by #{name}"
      end

      # Authorize
      authorize(*args)
    rescue Pundit::NotAuthorizedError # Map to 'Forbidden'
      raise Exceptions::Forbidden, "Access forbidden by #{name}"
    end

    def self.verify_csrf_token(ctx)
      return true if ctx[:is_graphql_introspection_generator]
      return true if Rails.env.development? && ctx[:controller].request.headers['SkipAuthenticityTokenCheck'] == 'true'

      ctx[:controller].send(:verify_csrf_token) # verify_csrf_token is private :(
    end

  end
end
