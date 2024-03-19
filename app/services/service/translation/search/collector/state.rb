# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::State < Service::Translation::Search::Collector
  private

  def list_sources
    Ticket::State.pluck(:name)
  end

  def search_sources
    Ticket::State.where("name #{like_operator} :query", query: like_query).pluck(:name)
  end
end
