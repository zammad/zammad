# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::Model < Service::Translation::Search::Collector
  def self.type
    :translation
  end

  def list
    Translation.not_customized.where(locale: locale).limit(limit).details
  end

  def search
    search_by_query.limit(limit).details
  end

  def count
    if mode == :list
      return Translation.not_customized.where(locale: locale).count
    end

    search_by_query.count
  end

  private

  def search_by_query
    Translation.not_customized.where(
      "locale = :locale AND (source #{like_operator} :query OR target #{like_operator} :query OR target_initial #{like_operator} :query)",
      locale: locale,
      query:  like_query
    )
  end
end
