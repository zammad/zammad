# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search < BaseQuery

    description 'Generic object search'

    argument :search,  String, description: 'What to search for'
    argument :only_in, Gql::Types::Enum::SearchableModelsType, description: 'Which model to search in, e.g. Ticket'

    argument :order_by, String, required: false, description: 'Set a custom order by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom order direction'

    argument :limit,   Integer, required: false, description: 'How many entries to find at maximum'
    argument :offset,  Integer, required: false, description: 'Offset to use for pagination'

    type Gql::Types::SearchResultType, null: false

    def resolve(search:, only_in:, order_by: nil, order_direction: nil, offset: 0, limit: 10)
      search_result = Service::Search.new(
        current_user: context.current_user,
        query:        search,
        objects:      [only_in],
        options:      { offset:, limit:, sort_by: [order_by].compact, order_by: [order_direction].compact }
      ).execute.result[only_in]

      return { total_count: 0, items: [] } if !search_result

      {
        total_count: search_result[:total_count],
        items:       search_result[:objects],
      }
    end
  end
end
