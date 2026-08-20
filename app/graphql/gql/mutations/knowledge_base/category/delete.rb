# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Category::Delete < KnowledgeBase::Base
    description 'Delete an empty knowledge base category.'

    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, loads_pundit_method: :destroy?, description: 'Category to delete.'

    field :success, Boolean, description: 'Was the mutation successful?'

    def resolve(category:)
      {
        success: Service::KnowledgeBase::Category::Delete
          .with_current_user(context.current_user)
          .execute(category:),
      }
    rescue ActiveRecord::DeleteRestrictionError
      # Subcategories and answers are not deleted along, so the user has to empty the category
      #   first. Same wording as the legacy delete dialog.
      error_response({ message: __('Delete all child categories and answers, then try again.') })
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
