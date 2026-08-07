# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Search::Collector::PublicLink < Service::Translation::Search::Collector
  private

  def list_sources
    @list_sources ||= display_titles | link_descriptions
  end

  def search_sources
    @search_sources ||= list_sources.select { |source| source.downcase.include?(query.downcase) }
  end

  def public_links
    @public_links ||= ::PublicLink.all
  end

  def display_titles
    public_links.pluck(:title)
  end

  def link_descriptions
    public_links.pluck(:description).compact
  end
end
