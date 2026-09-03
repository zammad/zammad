# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Reorder::Answers < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Set how the answers of a knowledge base category are ordered, and store their hand-made order. The subcategories of that category are a list of their own, unaffected by this (see KnowledgeBaseReorderCategories).'

    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, loads_pundit_method: :update?, description: 'Category whose answers are reordered.'

    # Stored in the category's `answerSortingMode`, a column of its own: the subcategories of the
    #   same category keep the mode they were given, so the picker offers one per list. Named
    #   without that prefix for the reason given on KnowledgeBaseReorderCategories.
    argument :sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, description: 'How the answers of that category are to be ordered from now on.'

    # Required with `manual` and refused with anything else, so the mode and the order it is read
    #   back in are always stored together — and every drag afterwards sends the whole order again.
    #   Note that the answers of a category are served through a paginated connection
    #   (Gql::Queries::KnowledgeBase::Answers), so a client has to have loaded every page before it
    #   can arm `manual` at all.
    #
    # Deliberately no `loads:`, for the reason given on
    #   Gql::Mutations::KnowledgeBase::Reorder::RootCategories.
    argument :answer_ids, [GraphQL::Types::ID], required: false, description: 'All answers of that category, in the wanted order. Required with `manual`, refused with any other mode, and always complete.'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The category with its updated `answerSortingMode`.'

    # Deliberately no field for the reordered answers, for the reason given on
    #   Gql::Mutations::KnowledgeBase::Reorder::RootCategories.
    def resolve(category:, sorting_mode:, answer_ids: nil)
      ordered_ids = answer_ids && Gql::ZammadSchema.internal_ids_from_ids(answer_ids, type: ::KnowledgeBase::Answer)

      updated = Service::KnowledgeBase::Reorder::Answers
        .with_current_user(context.current_user)
        .execute(category:, sorting_mode:, ordered_ids:)

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
