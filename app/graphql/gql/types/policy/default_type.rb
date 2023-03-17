# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      Pundit.authorize(context.current_user, @object, query)
    rescue Pundit::NotAuthorizedError
      false
    end
  end
end
