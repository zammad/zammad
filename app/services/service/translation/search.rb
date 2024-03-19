# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search < Service::Base
  attr_reader :locale, :query, :limit, :collector_mode

  def initialize(locale:, query:, limit: 150)
    super()

    @locale  = locale
    @query   = query
    @limit   = limit
    @collector_mode = query.blank? || query.strip.empty? ? :list : :search
  end

  def execute
    items = []
    total_count = 0

    Service::Translation::Search::Collector.collector_suggestions.each do |collector_module|
      collector = collector_module.new(locale:, query:, limit:, mode: collector_mode)

      # Filter out already existing suggestion from other collectors (e.g. same naming in object attributes and priority names).
      suggestions = collector.result.reject { |suggestion| items.pluck(:source).include?(suggestion[:source]) }

      items.concat(suggestions)

      total_count += suggestions.length
    end

    # Add existing translation at the end.
    items.concat(translations[:items])

    {
      items:       items.take(limit),
      total_count: total_count + translations[:total_count]
    }
  end

  private

  def translations
    @translations ||= begin
      items = []
      total_count = 0

      Service::Translation::Search::Collector.collector_translations.each do |collector_module|
        collector = collector_module.new(locale:, query:, limit:, mode: collector_mode)

        items.concat collector.result
        total_count += collector.count
      end

      {
        items:       items,
        total_count: total_count
      }
    end
  end
end
