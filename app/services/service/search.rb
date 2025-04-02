# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Search < Service::BaseWithCurrentUser
  Result = Struct.new(:result, :sorting) do
    def flattened
      result
        .in_order_of(:first, sorting)
        .flat_map { |elem| elem.last[:objects] }
    end
  end

  attr_reader :query, :objects, :options

  # @param current_user [User] which runs the search
  # @param query [String] to search for
  # @param objects [Array<ActiveRecord::Base>] searchable classes with search_preferences method present
  # @param options [Hash] options to forward to CanSearch and SearchIndexBackend. E.g. offset and limit.
  def initialize(current_user:, query:, objects:, options: {})
    super(current_user:)

    @query   = query
    @objects = objects
    @options = options
      .compact_blank
      .with_defaults(limit: 10) # limit can be overriden
      .merge!(with_total_count: true, full: true) # those options are mandatory; :only_total_count can still be passed and will override
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

    SearchIndexBackend
      .search_by_index(query, model.name, options)
      .tap do |result|
        next if result.blank?
        next if !result[:object_metadata] # in case of :only_total_count

        result[:objects] = model.where_ordered_ids(result[:object_metadata].pluck(:id))
      end
  end
end
