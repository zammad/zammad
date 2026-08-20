# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::KnowledgeBase::CategoryType < Policy::DefaultType
    description 'Access knowledge base category specific Pundit policy queries for the current object and user.'

    field :create_subcategory, Boolean, null: false, description: 'Is the user allowed to add a category under this category?'
    field :permissions, Boolean, null: false, description: 'Is the user allowed to see and change the permissions of this category?'

    # Not the inherited `update`/`destroy` pair: `destroy` is CategoryPolicy#destroy?, which asks
    #   about the *parent* (removing a category changes its parent's contents), while adding a
    #   child asks about this category itself.
    def create_subcategory
      pundit(:create_subcategory?)
    end

    def permissions
      pundit(:permissions?)
    end
  end
end
