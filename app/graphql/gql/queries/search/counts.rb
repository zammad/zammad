# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search::Counts < BaseQuery

    description 'Generic object search, finds only hit counts across models'

    argument :search,  String, description: 'What to search for'
    argument :only_in, [Gql::Types::Enum::SearchableModelsType], description: 'Which model to search in, e.g. Ticket'

    type [Gql::Types::Search::CountsResultType], null: false

    def resolve(search:, only_in:)
      search_results = Service::Search.new(
        current_user: context.current_user,
        query:        search,
        objects:      only_in,
        options:      { only_total_count: true }
      ).execute.result

      return [] if !search_results

      search_results.map do |model, result|
        {
          model:,
          total_count: result[:total_count],
        }
      end
    end
  end
end
