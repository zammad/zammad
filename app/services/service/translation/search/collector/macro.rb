# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::Macro < Service::Translation::Search::Collector
  private

  def list_sources
    ::Macro.pluck(:name)
  end

  def search_sources
    ::Macro.where("name #{like_operator} :query", query: like_query).pluck(:name)
  end
end
