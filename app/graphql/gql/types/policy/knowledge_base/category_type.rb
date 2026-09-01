# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::KnowledgeBase::CategoryType < Policy::DefaultType
    description 'Access knowledge base category specific Pundit policy queries for the current object and user.'

    field :create_answer, Boolean, null: false, description: 'Is the user allowed to create an answer in this category?'
    field :create_subcategory, Boolean, null: false, description: 'Is the user allowed to add a category under this category?'
    field :destroy_answer, Boolean, null: false, description: 'Is the user allowed to delete answers in this category?'
    field :update_answer, Boolean, null: false, description: 'Is the user allowed to edit the answers in this category?'
    field :permissions, Boolean, null: false, description: 'Is the user allowed to see and change the permissions of this category?'

    # Not the inherited `update`/`destroy` pair: `destroy` is CategoryPolicy#destroy?, which asks
    #   about the *parent* (removing a category changes its parent's contents), while adding a
    #   child — or acting on a child — asks about this category itself.
    def create_answer
      pundit(:create_answer?)
    end

    def create_subcategory
      pundit(:create_subcategory?)
    end

    # Asked of the category, not of each answer: KnowledgeBase::AnswerPolicy#destroy? resolves the
    #   same access through the answer's category, so every answer in one listing gives the same
    #   result.
    def destroy_answer
      pundit(:destroy_answer?)
    end

    def update_answer
      pundit(:update_answer?)
    end

    def permissions
      pundit(:permissions?)
    end
  end
end
