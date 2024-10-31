# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::DefaultType < Gql::Types::BaseObject
    description 'Access Pundit policy queries for the current object and user.'

    # `read` is implicit, as the record cannot be fetched without it.
    field :update, Boolean, null: false, description: 'Is the user allowed to update this object?'
    field :destroy, Boolean, null: false, description: 'Is the user allowed to delete this object?'

    def update
      pundit(:update?)
    end

    def destroy
      pundit(:destroy?)
    end

    private

    def pundit(query)
      Pundit.authorize(user, record, query)
    rescue Pundit::NotAuthorizedError
      false
    end

    def record
      @object
    end

    def user
      context.current_user
    end
  end
end
