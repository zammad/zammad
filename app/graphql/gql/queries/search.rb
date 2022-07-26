# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Search < BaseQuery

    description 'Generic object search'

    argument :query, String, required: true, description: 'What to search for'
    argument :limit, Integer, required: false, description: 'How many entries to find at maximum per model'

    type [Gql::Types::SearchResultType, { null: false }], null: false

    def resolve(query:, limit: 10)
      if SearchIndexBackend.enabled?
        # Performance optimization: some models may allow combining their Elasticsearch queries into one.
        result_by_model = combined_backend_search(query: query, limit: limit)

        # Other models require dedicated handling, e.g. for permission checks.
        result_by_model.merge!(models(direct_search_index: false).index_with do |model|
          model_search(model: model, query: query, limit: limit)
        end)

        # Finally, sort by object priority.
        models.map do |model|
          result_by_model[model]
        end.flatten
      else
        models.map do |model|
          model_search(model: model, query: query, limit: limit)
        end.flatten
      end
    end

    private

    # Perform a direct, cross-module Elasticsearch query and map the results by class.
    def combined_backend_search(query:, limit:)
      result_by_model = {}
      models_with_direct_search_index = models(direct_search_index: true).map(&:to_s)
      if models_with_direct_search_index
        SearchIndexBackend.search(query, models_with_direct_search_index, limit: limit).each do |item|
          klass = "::#{item[:type]}".constantize
          record = klass.lookup(id: item[:id])
          (result_by_model[klass] ||= []).push(record) if record
        end
      end
      result_by_model
    end

    # Call the model specific search, which will query Elasticsearch if available,
    #   or the Database otherwise.
    def model_search(model:, query:, limit:)
      model.search({ query: query, limit: limit, current_user: context.current_user })
    end

    SEARCHABLE_MODELS = [::Ticket, ::User, ::Organization].freeze

    # Get a prioritized list of searchable models
    def models(direct_search_index: nil)
      SEARCHABLE_MODELS.select do |model|
        prefs = model.search_preferences(context.current_user)
        next false if !prefs
        next false if direct_search_index.present? && !prefs[:direct_search_index] != direct_search_index

        true
      end.sort_by do |model|
        model.search_preferences(context.current_user)[:prio]
      end
    end
  end
end
