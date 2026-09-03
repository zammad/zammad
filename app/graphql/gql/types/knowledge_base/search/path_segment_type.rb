# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class Search::PathSegmentType < Gql::Types::BaseObject
    include Gql::Types::Concerns::ResolvesKnowledgeBaseLocale

    description 'One category on the path to a search result'

    # Deliberately not KnowledgeBaseCategory: granular permissions can leave a user without access
    #   to an ancestor of a category they may otherwise see, and the authorized type would then
    #   fail the whole search rather than just that breadcrumb. Titles of the containing path are
    #   what the legacy search list shows as a subtitle too, without checking the ancestors either.
    field :id, GraphQL::Types::ID, null: false, description: 'Category id, for linking the breadcrumb'

    # Carries the locale rather than exposing the category's translation, for the same reason: a
    #   translation is authorized through its category. This segment is keyed by its category's id,
    #   so without the argument it would hold one title for every locale asking - whichever was
    #   fetched last.
    field :title, String, description: 'Title in the given locale (falls back to the primary locale)' do
      argument :locale, String, required: false, description: 'System locale code to resolve the title for; defaults to the locale the query was resolved in'
    end

    def id
      Gql::ZammadSchema.id_from_object(object)
    end

    # Batched by the query, which asks this of every segment of every result; the fallback only
    #   runs where the type is resolved outside that flow.
    def title(locale: nil)
      requested    = requested_locale(locale)
      translations = context[:knowledge_base_category_translations] if requested == query_locale

      return translations[object.id]&.title if translations&.key?(object.id)

      object.translation_preferred(requested)&.title
    end

    private

    # The knowledge base a `locale` argument's code is looked up in.
    def locale_knowledge_base
      object.knowledge_base
    end
  end
end
