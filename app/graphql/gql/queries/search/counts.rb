# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search::Counts < BaseQuery

    description 'Generic object search, finds only hit counts across models'

    argument :search, String, required: false, description: 'What to search for'
    argument :only_in, [Gql::Types::Enum::SearchableModelsType], description: 'Which model to search in, e.g. Ticket'

    argument :filters, [Gql::Types::Input::Selector::ObjectInputType], required: false, description: 'Per-object advanced filters as selector conditions'

    type [Gql::Types::Search::CountsResultType], null: false

    def resolve(only_in:, search: nil, filters: nil)
      search_results = Service::Search
        .with_current_user(context.current_user)
        .execute(
          query:   search,
          objects: only_in,
          options: {
            per_object_conditions: per_object_conditions(filters),
            search_by_index:       true,
            only_total_count:      true,
          }.compact,
        ).result

      return [] if !search_results

      search_results.map do |model, result|
        {
          model:,
          total_count: result[:total_count],
        }
      end
    end

    private

    def per_object_conditions(filters)
      return if filters.blank?

      filters.to_h { |entry| [entry[:object], entry[:selector]] }
    end
  end
end
