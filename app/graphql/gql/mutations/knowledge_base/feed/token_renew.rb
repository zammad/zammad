# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Feed::TokenRenew < BaseMutation
    include Gql::Concerns::HandlesKnowledgeBaseFeed

    description 'Renew the access token of the internal knowledge base feeds, invalidating the previous feed URLs'

    argument :category_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category to offer an additional feed for; omit for the knowledge base root'
    argument :locale, String, required: false, description: 'System locale code the feeds should deliver'

    # The renewed paths come back with the mutation, so the caller can replace the
    #   ones it shows in one step instead of fetching them again.
    field :feed, Gql::Types::KnowledgeBase::FeedType, null: false, description: 'Feed paths carrying the renewed access token'

    requires_permission 'knowledge_base.*'

    def resolve(category: nil, locale: nil)
      { feed: knowledge_base_feed_paths(category:, locale:, renew: true) }
    end
  end
end
