# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class KnowledgeBase::ContentUpdates < BaseSubscription
    description 'Ping emitted when knowledge base content changes, so browse views can refetch'

    requires_permission 'knowledge_base.*'

    field :knowledge_base, Gql::Types::KnowledgeBaseType, null: true, description: 'The active knowledge base'
    field :affected_category_ids, [GraphQL::Types::ID], null:        true,
                                                        description: 'IDs of the changed category and its ancestors (whose counts/visibility may change); empty for knowledge-base-wide changes'

    # The actual changed data is per-user (visibility, granular permissions) and a
    #   single change invalidates tree-wide counts, so this stays a ping: subscribers
    #   refetch the scoped browse queries. `affectedCategoryIds` lets a client skip the
    #   refetch when the change is in a branch it is not currently viewing.
    def update(...)
      categories = object.is_a?(Hash) ? Array(object[:categories]) : []

      {
        knowledge_base:        ::KnowledgeBase.active.first,
        affected_category_ids: categories.map { |category| Gql::ZammadSchema.id_from_object(category) },
      }
    end
  end
end
