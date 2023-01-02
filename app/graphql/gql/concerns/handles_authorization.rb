# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    #
    # Internal methods
    #

    # This method is used by GraphQL to perform authorization on the various objects.
    def self.authorized?(*args)
      # ctx = args[-1] # This may be called with 2 or 3 params, context is last.

      before_authorize(*args)

      # Authorize
      authorize(*args)
    rescue Pundit::NotAuthorizedError # Map to 'Forbidden'
      raise Exceptions::Forbidden, "Access forbidden by #{name}"
    end

  end
end
