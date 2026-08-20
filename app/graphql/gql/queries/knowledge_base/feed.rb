# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Feed < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseFeed

    description 'Fetch the feed paths of the internal knowledge base for the current user'

    argument :category_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category to offer an additional feed for; omit for the knowledge base root'
    argument :locale, String, required: false, description: 'System locale code the feeds should deliver'

    type Gql::Types::KnowledgeBase::FeedType, null: false

    requires_permission 'knowledge_base.*'

    def resolve(category: nil, locale: nil)
      knowledge_base_feed_paths(category:, locale:)
    end
  end
end
