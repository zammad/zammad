# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class FeedType < Gql::Types::BaseObject
    description 'Feed paths of the internal knowledge base, including the access token'

    field :knowledge_base_path, String, null: false, description: 'Feed covering all updates of the knowledge base'
    field :category_path, String, null: true, description: 'Feed covering the browsed category including its sub-categories (null at the knowledge base root)'
  end
end
