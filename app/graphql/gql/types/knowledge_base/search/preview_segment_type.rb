# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class Search::PreviewSegmentType < Gql::Types::BaseObject
    description 'One run of text in a search preview, either matched or not'

    field :text, String, null: false, description: 'Plain text, safe to render as text'
    field :highlight, Boolean, null: false, description: 'Whether this run matched the search term and should be marked'
  end
end
