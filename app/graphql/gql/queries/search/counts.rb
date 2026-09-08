# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search::Counts < BaseQuery
    include Gql::Concerns::SearchesKnowledgeBaseAnswers

    description 'Generic object search, finds only hit counts across models'

    argument :search, String, required: false, description: 'What to search for'
    argument :only_in, [Gql::Types::Enum::SearchableModelsType], description: 'Which model to search in, e.g. Ticket'

    argument :filters, [Gql::Types::Input::Selector::ObjectInputType], required: false, description: 'Per-object advanced filters as selector conditions'

    type [Gql::Types::Search::CountsResultType], null: false

    def resolve(only_in:, search: nil, filters: nil)
      # `uniq` so a repeated model is reported once and searched once. The generic branch got that
      #   for free - Service::Search answers with a hash keyed by model - and this branch has to keep
      #   the same promise, at 200 permission-filtered hits per extra pass.
      generic, answers = only_in.uniq.partition { |model| !knowledge_base_answers?(model) }

      generic_counts(generic, search, filters) + answers.flat_map { |model| answer_counts(model, search) }
    end

    private

    def generic_counts(objects, search, filters)
      return [] if objects.empty?

      search_results = Service::Search
        .with_current_user(context.current_user)
        .execute(
          query:   search,
          objects: objects,
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

    # Counted the only way this model can be: by asking for the hits and sizing them. The knowledge
    #   base's backend materialises and permission-filters in Ruby, so there is no count-only path to
    #   take - and the number is bounded by the service's result cap either way, which is why the
    #   story promises a lower bound rather than an exact total.
    #
    # Omitted rather than reported as 0 when there is nothing to search, matching what the generic
    #   branch does for a model Service::Search declines.
    def answer_counts(model, search)
      hits = knowledge_base_answer_hits(search)
      return [] if hits.nil?

      [{ model:, total_count: hits.size }]
    end

    def per_object_conditions(filters)
      return if filters.blank?

      filters.to_h { |entry| [entry[:object], entry[:selector]] }
    end
  end
end
