# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How far a search pages: Elasticsearch refuses a page that ends beyond the index's result window, which an admin may
#   set per model; a search on the database has no such bound.
module Service::AI::Tool::Search::ResultWindow
  # @param model [Class] the model searched
  # @param query [String, nil] the query as the search gets it
  # @return [Integer, nil] nil where the search runs on the database
  def self.of(model, query:)
    SearchIndexBackend.max_result_window(model) if model.search_by_index?(query:)
  end

  # Whether a page of limit records from offset fits, with the one more record that tells whether more follow.
  def self.fits?(window, offset:, limit:)
    window.nil? || offset + limit < window
  end

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  def self.more_text(has_more:, next_cursor:)
    return 'No more follow.' if !has_more
    return "More follow: call again with the same arguments and cursor \"#{next_cursor}\"." if next_cursor

    'More follow, but the search pages no further. Narrow the query to see them.'
  end
end
