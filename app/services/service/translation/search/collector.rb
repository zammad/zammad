# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector
  include Mixin::RequiredSubPaths

  attr_reader :locale, :query, :like_query, :like_operator, :limit, :mode

  def self.collector_suggestions
    @collector_suggestions ||= descendants.select { |collector| collector.type == :suggestion }
  end

  def self.collector_translations
    @collector_translations ||= descendants.select { |collector| collector.type == :translation }
  end

  def self.type
    :suggestion
  end

  def initialize(locale:, query:, limit:, mode:)
    super()

    @locale = locale
    @query  = query
    @limit  = limit
    @mode   = mode

    return if mode == :list

    @like_query = "%#{SqlHelper.quote_like(query)}%"
    @like_operator = Rails.application.config.db_like
  end

  def result
    @result ||= begin
      mode == :list ? list : search
    end
  end

  def list
    raise NotImplementedError if self.class.type != :suggestion

    suggestions(list_sources)
  end

  def search
    raise NotImplementedError if self.class.type != :suggestion

    suggestions(search_sources)
  end

  def count
    raise NotImplementedError
  end

  private

  def list_sources
    raise NotImplementedError
  end

  def search_sources
    raise NotImplementedError
  end

  def suggestions(sources)
    result = []

    sources.each do |source|
      next if Translation.find_source(locale, source)

      result.push({
                    source:,
                    target:         '',
                    target_initial: '',
                    id:             SecureRandom.uuid,
                  })
    end

    result
  end
end
