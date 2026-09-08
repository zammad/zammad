# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search < BaseQuery
    include Gql::Concerns::SearchesKnowledgeBaseAnswers

    description 'Generic object search'

    argument :search, String, required: false, description: 'What to search for'
    argument :only_in, Gql::Types::Enum::SearchableModelsType, description: 'Which model to search in, e.g. Ticket'

    argument :order_by, String, required: false, description: 'Set a custom order by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom order direction'

    argument :limit, Integer, required: false, description: 'How many entries to find at maximum'
    argument :offset, Integer, required: false, description: 'Offset to use for pagination'

    argument :filter, Gql::Types::Input::Selector::NodeInputType, required: false, description: 'Advanced filters as selector conditions'

    type Gql::Types::SearchResultType, null: false

    def resolve(only_in:, search: nil, order_by: nil, order_direction: nil, offset: 0, limit: 10, filter: nil)
      return knowledge_base_answer_result(search, offset:, limit:) if knowledge_base_answers?(only_in)

      search_result = Service::Search
        .with_current_user(context.current_user)
        .execute(
          query:   search,
          objects: [only_in],
          options: {
            condition:       filter,
            search_by_index: true,
            offset:,
            limit:,
            sort_by:         [order_by].compact,
            order_by:        [order_direction].compact,
          },
        ).result[only_in]

      return { total_count: 0, items: [] } if !search_result

      {
        total_count: search_result[:total_count],
        items:       search_result[:objects],
      }
    end

    private

    # `total_count` is the whole permitted result set, `items` the requested window of it — the same
    #   contract Service::Search answers with, so the quicksearch group's "%s more" arithmetic works
    #   unchanged.
    #
    # `order_by`, `order_direction` and `filter` have no meaning here and are ignored: the knowledge
    #   base's backend ranks by relevance, and it knows no selector conditions. Nothing sends them:
    #   the search plugin sets `filtersDisabled`, and its detail table declares every column
    #   `noSorting`, so the answers tab offers no control that could produce an order.
    def knowledge_base_answer_result(search, offset:, limit:)
      hits = knowledge_base_answer_hits(search)

      return { total_count: 0, items: [] } if hits.nil?

      {
        total_count: hits.size,
        items:       hits.slice(offset.clamp(0, hits.size), limit) || [],
      }
    end
  end
end
