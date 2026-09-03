# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Reorder::Categories < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Set how the subcategories of a knowledge base category are ordered, and store their hand-made order. The answers of that category are a list of their own, unaffected by this (see KnowledgeBaseReorderAnswers).'

    argument :parent_category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, loads_pundit_method: :update?, description: 'Category whose subcategories are reordered.'

    # Stored in the category's `categorySortingMode`. Named without that prefix because the mutation
    #   already says which of the category's two lists it orders — as its `categoryIds` argument
    #   does, and as KnowledgeBaseReorderAnswers' `sortingMode` does for the other one.
    argument :sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, description: 'How the subcategories of that category are to be ordered from now on.'

    # Required with `manual` and refused with anything else, so the mode and the order it is read
    #   back in are always stored together — and every drag afterwards sends the whole order again.
    #
    # Deliberately no `loads:`, for the reason given on
    #   Gql::Mutations::KnowledgeBase::Reorder::RootCategories.
    argument :category_ids, [GraphQL::Types::ID], required: false, description: 'All subcategories of that category, in the wanted order. Required with `manual`, refused with any other mode, and always complete.'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The category with its updated `categorySortingMode`.'

    # Deliberately no field for the reordered subcategories, for the reason given on
    #   Gql::Mutations::KnowledgeBase::Reorder::RootCategories.
    def resolve(parent_category:, sorting_mode:, category_ids: nil)
      ordered_ids = category_ids && Gql::ZammadSchema.internal_ids_from_ids(category_ids, type: ::KnowledgeBase::Category)

      updated = Service::KnowledgeBase::Reorder::Categories
        .with_current_user(context.current_user)
        .execute(parent: parent_category, sorting_mode:, ordered_ids:)

      # No locale is asked of the caller — a sorting mode has nothing to do with one — but the
      #   category that is rendered back carries locale-dependent fields (title, visibility,
      #   breadcrumb titles), so the payload is localized in the current user's preferred locale.
      store_knowledge_base_locale(updated.knowledge_base, nil)

      { category: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
