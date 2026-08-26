# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class Search::PathSegmentType < Gql::Types::BaseObject
    description 'One category on the path to a search result'

    # Deliberately not KnowledgeBaseCategory: granular permissions can leave a user without access
    #   to an ancestor of a category they may otherwise see, and the authorized type would then
    #   fail the whole search rather than just that breadcrumb. Titles of the containing path are
    #   what the legacy search list shows as a subtitle too, without checking the ancestors either.
    field :id, GraphQL::Types::ID, null: false, description: 'Category id, for linking the breadcrumb'
    field :title, String, description: 'Title in the requested locale (falls back to the primary locale)'

    def id
      Gql::ZammadSchema.id_from_object(object)
    end

    # Batched by the query, which asks this of every segment of every result; the fallback only
    #   runs where the type is resolved outside that flow.
    def title
      titles = context[:knowledge_base_category_titles]
      return titles[object.id] if titles&.key?(object.id)

      object.translation_preferred(context[:knowledge_base_locale])&.title
    end
  end
end
