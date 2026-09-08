# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Search < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Search the knowledge base for answers or categories'

    argument :query, String, description: 'What to search for'
    # One kind per result list, so the two can be paged and counted apart. A client that shows
    #   both counts runs this query once per kind and renders one of them, which is what the
    #   desktop view does.
    argument :entity, Gql::Types::Enum::KnowledgeBase::SearchEntityType, required: true, default_value: :answer, description: 'Which kind of content to search for; the result list holds that kind alone'
    argument :category_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Restrict the search to this category and its subcategories'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    type Gql::Types::KnowledgeBase::Search::ResultType.connection_type, null: false

    def resolve(query:, entity:, category: nil, locale: nil)
      knowledge_base = resolve_searchable_knowledge_base(category, locale)

      output = ::Service::KnowledgeBase::Search
        .with_current_user(context.current_user)
        .execute(query:, knowledge_base:, entity:, scope: category, locale: context[:knowledge_base_locale])

      # Hand the batched per-category data to the types, so the titles on the result items and on
      #   their category paths resolve without a query each (#translation_preferred queries per
      #   call), and the visibility of a category hit without walking its subtree per publication
      #   state (#content_visibility does). Same handover as
      #   Gql::Queries::KnowledgeBase::CategorySubcategories.
      context.scoped_set!(:knowledge_base_category_translations, output.category_translations)
      context.scoped_set!(:knowledge_base_category_visibility, output.category_visibility)

      output.results
    end
  end
end
