# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class PolicyType < Gql::Types::BaseObject
    description 'Access Pundit policy queries for the current object and user.'

    # `read` is implicit, as the record cannot be fetched without it.
    field :update, Boolean, null: false
    field :destroy, Boolean, null: false

    def update
      pundit(:update?)
    end

    def destroy
      pundit(:destroy?)
    end

    private

    def pundit(query)
      Pundit.authorize(context.current_user, @object, query)
    rescue Pundit::NotAuthorizedError
      false
    end
  end
end
