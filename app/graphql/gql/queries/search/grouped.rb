# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search::Grouped < BaseQuery
    include Gql::Concerns::SearchesKnowledgeBaseAnswers

    description 'Generic object search across models, finds items grouped by model'

    argument :search, String, required: false, description: 'What to search for'
    argument :only_in, [Gql::Types::Enum::SearchableModelsType], description: 'Which models to search in, e.g. Ticket'

    argument :limit, Integer, required: false, validates: { numericality: { greater_than_or_equal_to: 0 } }, description: 'How many entries to find at maximum per model'

    type [Gql::Types::Search::GroupedResultType], null: false

    # Groups come in the search service's model priority order, followed by knowledge base answers.
    #   A model the user may not search, or a knowledge base that is not active, is omitted rather
    #   than failing the whole field.
    def resolve(only_in:, search: nil, limit: 10)
      generic, answers = only_in.uniq.partition { |model| !knowledge_base_answers?(model) }

      generic_groups(generic, search, limit) + answers.flat_map { |model| answer_groups(model, search, limit) }
    end

    private

    def generic_groups(objects, search, limit)
      return [] if objects.empty?

      search_results = Service::Search
        .with_current_user(context.current_user)
        .execute(
          query:   search,
          objects: objects,
          options: {
            search_by_index: true,
            limit:,
          },
        ).result

      search_results.map do |model, result|
        {
          model:,
          total_count: result[:total_count],
          items:       result[:objects],
        }
      end
    end

    def answer_groups(model, search, limit)
      hits = knowledge_base_answer_hits(search)
      return [] if hits.nil?

      [{ model:, total_count: hits.size, items: hits.first(limit) }]
    end
  end
end
