# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# Implements GraphQL type logic for field authorization.
# See also `Gql::Concerns::SkipsUnauthorizedFields`
module Gql::Concerns::CanAuthorizeFields
  extend ActiveSupport::Concern

  included do
    def by_permissions(permissions)
      context.current_user.permissions? permissions
    end

    def by_pundit
      # Only authorize object once, and then memoize the result for more fields on it.
      return @pundit_result if @pundit_result.present?

      @pundit_result = begin
        Pundit.authorize context.current_user, object, :show?
      rescue Pundit::NotAuthorizedError
        false
      end
    end
  end
end
