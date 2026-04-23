# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Search < Service::Base
  Result = Struct.new(:result, :sorting) do
    def flattened
      result
        .in_order_of(:first, sorting)
        .flat_map { |elem| elem.last[:objects] }
    end
  end

  attr_reader :query, :objects, :options

  # @param query [String] to search for
  # @param objects [Array<ActiveRecord::Base>] searchable classes with search_preferences method present
  # @param options [Hash] options to forward to CanSearch and SearchIndexBackend. E.g. offset and limit.
  # @option options [Boolean] :only_ids, if true, only return object ids instead of full objects (default: false)
  def initialize(query:, objects:, options: {})
    @query   = query
    @objects = objects
    @options = prepare_options(options)
  end

  def execute
    result = models_sorted
      .index_with { |elem| search_single_model(elem) }
      .compact

    Result.new(result, models_sorted)
  end

  private

  def models
    @models ||= objects
      .index_with { |elem| elem.search_preferences(current_user) }
      .compact_blank
  end

  def models_sorted
    @models_sorted ||= models.keys.sort_by { |elem| models.dig(elem, :prio) }.reverse
  end

  def search_single_model(model)
    if !SearchIndexBackend.enabled? || !models.dig(model, :direct_search_index)
      return model.search(query:, current_user:, **options)
    end

    result = SearchIndexBackend.search_by_index(query, model.name, options)
    enrich_with_metadata model, result
  end

  def enrich_with_metadata(model, result)
    return result if result.blank?

    if options[:only_ids]
      return result.pluck(:id)
    end

    if result[:object_metadata] # if this is not :only_total_count
      object_ids       = result[:object_metadata].pluck(:id)
      result[:objects] = model.where_ordered_ids(object_ids)
    end

    result
  end

  def prepare_options(input)
    output = input
      .compact_blank
      .with_defaults(limit: 10) # limit can be overriden
      .merge(with_total_count: true, full: true) # those options are mandatory; :only_total_count can still be passed and will override

    if output[:only_ids]
      output[:with_total_count] = false
      output[:full] = false
    end

    output
  end
end
