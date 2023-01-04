# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Search < Service::BaseWithCurrentUser
  def execute(term:, objects:, options: { limit: 10 })
    options[:limit] = 10 if options[:limit].blank?

    perform_search(term: term, objects: objects, options: options)
  end

  def perform_search(term:, objects:, options:)
    if SearchIndexBackend.enabled?
      # Performance optimization: some models may allow combining their Elasticsearch queries into one.
      result_by_model = combined_backend_search(term: term, objects: objects, options: options)

      # Other models require dedicated handling, e.g. for permission checks.
      result_by_model.merge!(models(objects: objects, direct_search_index: false).index_with do |model|
        model_search(model: model, term: term, options: options)
      end)

      # Finally, sort by object priority.
      models(objects: objects).map do |model|
        result_by_model[model]
      end.flatten
    else
      models(objects: objects).map do |model|
        model_search(model: model, term: term, options: options)
      end.flatten
    end
  end

  # Perform a direct, cross-module Elasticsearch query and map the results by class.
  def combined_backend_search(term:, objects:, options:)
    result_by_model = {}
    models_with_direct_search_index = models(objects: objects, direct_search_index: true).map(&:to_s)
    if models_with_direct_search_index
      SearchIndexBackend.search(term, models_with_direct_search_index, options).each do |item|
        klass = "::#{item[:type]}".constantize
        record = klass.lookup(id: item[:id])
        (result_by_model[klass] ||= []).push(record) if record
      end
    end
    result_by_model
  end

  # Call the model specific search, which will query Elasticsearch if available,
  #   or the Database otherwise.
  def model_search(model:, term:, options:)
    model.search({ query: term, current_user: current_user, limit: options[:limit], ids: options[:ids] })
  end

  # Get a prioritized list of searchable models
  def models(objects:, direct_search_index: nil)
    objects.select do |model|
      prefs = model.search_preferences(current_user)
      next false if !prefs
      next false if direct_search_index.present? && !prefs[:direct_search_index] != direct_search_index

      true
    end.sort_by do |model|
      model.search_preferences(current_user)[:prio]
    end.reverse
  end
end
