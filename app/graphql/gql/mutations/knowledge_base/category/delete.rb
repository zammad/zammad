# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Category::Delete < KnowledgeBase::Base
    description 'Delete an empty knowledge base category.'

    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, loads_pundit_method: :destroy?, description: 'Category to delete.'

    field :success, Boolean, description: 'Was the mutation successful?'

    # No service behind this one: the argument's `destroy?` gate has already authorized the record,
    #   which leaves a single `destroy!` — there is nothing for a service to hold.
    #
    # A category with subcategories or answers is not deleted recursively: both associations are
    #   `dependent: :restrict_with_exception`, so `destroy!` raises and the user has to empty the
    #   category first, which is a deliberate, explicit step.
    def resolve(category:)
      # Deleting is editing knowledge base content, so it follows the same rule as the write
      #   services: only an active knowledge base is editable.
      ::KnowledgeBase.active.first!

      category.destroy!

      { success: true }
    rescue ActiveRecord::DeleteRestrictionError
      # Same wording as the legacy delete dialog.
      error_response({ message: __('Delete all child categories and answers, then try again.') })
    end
  end
end
