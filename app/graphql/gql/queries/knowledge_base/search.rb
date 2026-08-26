# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Search < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Search the knowledge base for answers and categories'

    argument :query, String, description: 'What to search for'
    argument :category_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Restrict the search to this category and its subcategories'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    type Gql::Types::KnowledgeBase::Search::ResultType.connection_type, null: false

    def resolve(query:, category: nil, locale: nil)
      knowledge_base = category&.knowledge_base || ::KnowledgeBase.active.first

      # Only the active knowledge base is browsable — a category loaded by GID must not expose
      #   content from an inactive one.
      return [] if knowledge_base.nil? || !knowledge_base.active?

      store_knowledge_base_locale(knowledge_base, locale)

      # The type-level authorization is locale-agnostic; enforce the browsed locale here too, so a
      #   category hidden from this locale's listing cannot be used as a search scope.
      if category && !category.visible_to_user?(context.current_user, context[:knowledge_base_locale])
        raise Exceptions::Forbidden, "Category #{category.id} is not visible in the requested locale"
      end

      output = ::Service::KnowledgeBase::Search
        .with_current_user(context.current_user)
        .execute(query:, knowledge_base:, scope: category, locale: context[:knowledge_base_locale])

      # Hand the batched per-category data to the types, so the titles on the result items and on
      #   their category paths resolve without a query each (#translation_preferred queries per
      #   call), and the visibility of a category hit without walking its subtree per publication
      #   state (#content_visibility does). Same handover as
      #   Gql::Queries::KnowledgeBase::CategorySubcategories.
      context.scoped_set!(:knowledge_base_category_titles, output.category_titles)
      context.scoped_set!(:knowledge_base_category_translation_missing, output.category_translation_missing)
      context.scoped_set!(:knowledge_base_category_visibility, output.category_visibility)

      output.results
    end
  end
end
