# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::Tool::Concerns::RecordSearch
  DEFAULT_LIMIT = 10
  MAX_LIMIT     = 50

  # Discourage wildcard retries after an empty result: Elasticsearch appends one, and the database matches any part.
  NONE_HINT = 'A word already matches the start of a longer one, so a wildcard finds no more.'.freeze # rubocop:disable Zammad/DetectTranslatableString

  def execute
    return search_result if argument(:cursor)

    Service::AI::Tool::Runtime::SearchCount.noted_result(search_result, run:)
  end

  private

  def search_result
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this search. #{Service::AI::Tool::CURSOR_HINT} the first #{record_noun}.") if offset.nil?
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "The query holds no word to look for. #{query_hint}") if query.nil?

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  rescue SearchIndexBackend::SearchFailedError => e
    Rails.logger.error "AI tool #{self.class.tool_name} could not search: #{e.message}"
    Service::AI::Tool::Runtime::Result.error('search_failed', "The search could not run. Search by plain words; if that fails as well, tell the user that the #{record_noun} search does not work right now.")
  end

  # A lone wildcard is no word: it would list every record.
  def query
    Service::AI::Tool::Search::QueryWords.search_text(argument(:query))
  end

  def limit
    argument(:limit)
  end

  def offset
    cursor_offset
  end

  def content
    @content ||= {
      query:       argument(:query).to_s.squish,
      result_key => rows,
      has_more:    more?,
      next_cursor: (next_cursor_at(offset + limit) if more?),
    }.compact
  end

  def found_ids
    @found_ids ||= search_ids
  end

  def search_ids
    model.search(
      current_user:     current_user,
      query:            query,
      limit:            limit + 1,
      offset:           offset,
      sort_by:          sorting.first,
      order_by:         sorting.last,
      full:             false,
      # A query Elasticsearch cannot run must not read as one without matches.
      raise_on_failure: true,
    ).to_a.map(&:to_i)
  end

  # The search bar's order by the last update would move a record touched between two pages, as every ticket change
  #   touches its customer; the ID keeps records created at the same time in one order.
  def sorting
    sorted? ? search_sorting('created_at') : [%w[active created_at id], %w[desc desc desc]]
  end

  # Indexed records may lag behind the database while their update job is pending; one deleted since is left out.
  def page
    @page ||= begin
      ids     = found_ids.first(limit)
      records = model.where(id: ids).includes(row_includes).index_by(&:id)

      ids.filter_map { |id| records[id] }.select { |record| readable?(record) }
    end
  end

  def more?
    found_ids.size > limit
  end

  def rows
    @rows ||= page.map { |record| row(record) }
  end

  def row_includes
    []
  end

  def text
    header = AI::PromptText.xml_text("#{record_noun.pluralize.capitalize} matching \"#{content[:query]}\"")
    return "#{header}: none. #{NONE_HINT}" if rows.empty?

    more = content[:has_more] ? "More follow: call again with the same arguments and cursor \"#{content[:next_cursor]}\"." : 'No more follow.' # rubocop:disable Zammad/DetectTranslatableString

    ["#{header}:", AI::PromptText.xml_text(rows.map { |row| line(row).squish }.join("\n")), more, detail_hint].join("\n\n")
  end
end
