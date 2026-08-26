# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class Search::ResultType < Gql::Types::BaseObject
    description 'One knowledge base search hit, with the previews that show why it matched'

    field :item, Gql::Types::KnowledgeBase::Search::ItemType, null: false, description: 'The found answer or category'

    field :title_preview, [Gql::Types::KnowledgeBase::Search::PreviewSegmentType, { null: false }],
          null: false, description: 'The title, split into matched and unmatched runs'
    field :body_preview, [Gql::Types::KnowledgeBase::Search::PreviewSegmentType, { null: false }],
          null: false, description: 'Excerpt of the body around the match, split into matched and unmatched runs; empty for a category'

    field :category_path, [Gql::Types::KnowledgeBase::Search::PathSegmentType, { null: false }],
          null: false, description: 'Categories leading to this hit, root first; empty at the top level'
  end
end
