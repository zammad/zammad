# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Concern::HandlesAuthorization
  extend ActiveSupport::Concern

  included do

    def self.requires_authentication?
      true
    end

    def self.authorize(...)
      true
    end

    # This may be called with 2 or 3 params.
    def self.authorized?(*args)
      ctx = args[-1]
      if requires_authentication? && !ctx[:current_user]
        return false
      end

      authorize(*args)
    rescue Pundit::NotAuthorizedError
      false
    end

  end
end
