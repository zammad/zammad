# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    #
    # Customizable methods
    #

    # Override this method to implement additional handlers.
    def self.before_authorize(...)
      true
    end

    # Override this method if an object requires custom authorization, e.g. based on Pundit.
    def self.authorize(...)
      true # Authorization is granted by default.
    end

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

    #
    # Internal methods
    #

    # This method is used by GraphQL to perform authorization on the various objects.
    def self.authorized?(*)
      # ctx = args[-1] # This may be called with 2 or 3 params, context is last.

      before_authorize(*)

      # Authorize
      authorize(*)
    rescue Pundit::NotAuthorizedError # Map to 'Forbidden'
      raise Exceptions::Forbidden, "Access forbidden by #{name}"
    end

  end
end
