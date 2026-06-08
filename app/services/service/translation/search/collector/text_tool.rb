# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::TextTool < Service::Translation::Search::Collector
  private

  def list_sources
    ::AI::TextTool.pluck(:name)
  end

  def search_sources
    ::AI::TextTool.where('name ILIKE :query', query: like_query).pluck(:name)
  end
end
