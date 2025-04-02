# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::Overview < Service::Translation::Search::Collector
  private

  def list_sources
    ::Overview.pluck(:name)
  end

  def search_sources
    ::Overview.where("name #{like_operator} :query", query: like_query).pluck(:name)
  end
end
