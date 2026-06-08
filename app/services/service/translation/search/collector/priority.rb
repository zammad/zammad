# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::Priority < Service::Translation::Search::Collector
  private

  def list_sources
    Ticket::Priority.pluck(:name)
  end

  def search_sources
    Ticket::Priority.where('name ILIKE :query', query: like_query).pluck(:name)
  end
end
