# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Searches the knowledge base answers the user may read, published internally or publicly, in one of two modes. The
#   default "semantic" searches by meaning, with a verdict on how well the answers fit, where the vector index holds the
#   current embedding model's vectors; where it cannot, the search runs by words and the result says why, in
#   "semantic_search": pending, off or failed (ready where the search by meaning ran). The mode "keyword" searches by
#   words on purpose, without a verdict. A search by words whose index does not answer is "keyword_search": failed, and
#   where no way of searching found anything, the result is an error: a failed search is no search without matches. In
#   both, identifiers in the query, such as error codes, are looked for as words too, since a search by meaning loses
#   them and a search by words lets longer codes crowd them out. Each answer is a row as in every tool, with its text or
#   the passage that matched (Service::AI::Tool::Output).
class Service::AI::Tool::SearchKnowledgeBase < Service::AI::Tool
  DEFAULT_LIMIT      = 5
  MAX_LIMIT          = 10
  TEXT_LENGTH        = 2_000
  EXCERPT_LENGTH     = 300
  FULL_TEXTS         = 2
  KEYWORD_CANDIDATES = 50
  IDENTIFIER_BATCH   = 100

  # How far the pages of one search reach: as many answers as the search by words takes as candidates.
  RANKED = KEYWORD_CANDIDATES

  # semantic_search is nil where the model chose a search by words, keyword_search nil where the search by words did not
  #   fail. The hits are the ranked answers up to the end of the page and one more.
  Found = Data.define(:mode, :semantic_search, :keyword_search, :coverage, :hits)

  # rubocop:disable Zammad/DetectTranslatableString
  COVERAGE_TEXTS = {
    'covered' => 'Coverage: covered — the first answer is clearly the closest to the question.',
    'weak'    => 'Coverage: weak — none of the answers is clearly closer to the question than the others. Judge each ' \
                 'one; if none of them answers it, search again: rephrased, or by words for an exact term.',
    'none'    => 'Coverage: none — no knowledge base answer is close to this query. That does not mean the knowledge ' \
                 'base lacks the topic: search again with a more general query, or by words for an exact term — about ' \
                 'three searches for one question in all.',
    'unknown' => 'Coverage: unknown — judge whether the answers fit the question.',
  }.freeze

  # Why the search by meaning did not run.
  UNREADY_TEXTS = {
    'pending' => 'the search by meaning is not ready yet, its index is being built',
    'off'     => 'this helpdesk has no search by meaning',
    'failed'  => 'the search by meaning failed',
  }.freeze

  # How the search ran, by the readiness of the search by meaning; "keyword" where the model chose a search by words.
  SEARCH_TEXTS = {
    'ready'   => 'by meaning.',
    'keyword' => 'by words.',
    **UNREADY_TEXTS.transform_values { |text| "by words: #{text}." },
  }.freeze

  NOT_SEARCHED     = 'This says nothing about whether the knowledge base covers the question.'.freeze
  KEYWORD_FAILED   = 'The search by words failed: only answers that hold an identifier of the query are listed.'.freeze

  NO_KEYWORD_MATCH = 'No answer contains all of these words. Search again with fewer or other words.'.freeze
  NO_SYNTAX        = 'This Zammad searches without Elasticsearch and takes plain words only: a field such as title: or ' \
                     'tags: is not searched. Search by words.'.freeze
  NO_CHOSEN_MATCH  = 'No answer contains all of these words. Search again with fewer words, or by meaning with a more ' \
                     'general query.'.freeze
  READ_IN_FULL     = 'A text that is cut can be read in full with get_knowledge_base_answer and the answer\'s ID.'.freeze
  LATER_PAGE       = 'A later page of the search: each answer shows the passage that matched; the verdict on how well the ' \
                     'answers fit comes with the first page.'.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      query:           { type: 'string' },
      mode:            { enum: %w[semantic keyword], description: 'How the search ran: by meaning or by words.' },
      semantic_search: {
        enum:        %w[ready off pending failed],
        description: 'Whether the search by meaning could run where it was asked for; off, pending and failed searched by words instead.',
      },
      keyword_search:  { const: 'failed', description: 'The search by words failed: only answers that hold an identifier of the query are listed.' },
      coverage:        {
        enum:        %w[covered weak none unknown],
        description: 'How well the answers fit, on the first page: covered, weak, none, or unknown for a search by words.',
      },
      answers:         {
        type:  'array',
        items: Service::AI::Tool::Output::KnowledgeBaseAnswer.part_schema(contains: { type: 'string', description: 'An identifier of the query the answer holds.' }),
      },
      has_more:        { type: 'boolean' },
      next_cursor:     { type: 'string', description: 'Pass it as cursor, with the same other arguments, for the next answers.' },
    },
    required:   %w[query mode answers has_more],
  }.freeze

  description 'Search the knowledge base of Zammad for how something is done or what the team decided, by words ' \
              '(mode "keyword") or by meaning (mode "semantic"). By words, the query takes words or Lucene query ' \
              'syntax, as Zammad\'s knowledge base search does: fields such as title: or tags:, quotes for a phrase, ' \
              'AND, OR, NOT. By meaning, it takes a ' \
              'short question and says how well the answers fit. The best answers come with their text, the others ' \
              'with the part that matched; get_knowledge_base_answer reads one in full. Pass next_cursor as cursor, ' \
              'with the same other arguments, for more answers.',
              harness: 'Without mode, it searches by meaning.',
              mcp:     'Without mode, it searches by words.'
  # rubocop:disable-next Zammad/DetectTranslatableString
  title 'Search knowledge base'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents
  always_loaded
  searches

  parameter :query, type: :string, required: true, description: 'What to look for: a short question or a few words.' # rubocop:disable Zammad/DetectTranslatableString
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT,
                    description: 'How many answers to return.' # rubocop:disable Zammad/DetectTranslatableString
  parameter :mode, type: :string, enum: %w[semantic keyword], default: 'semantic', mcp_default: 'keyword',
                   description:     'semantic (the default) searches by meaning, also across languages. keyword searches ' \
                                    'by words, for an exact code, setting name, product term or title that a search by ' \
                                    'meaning can miss. Write one to three words as they stand in an answer: codes and ' \
                                    'names as written, other words in a language of the knowledge base.',
                   mcp_description: 'keyword (the default) searches by words: write one to three words as they stand in ' \
                                    'an answer, codes and names as written, other words in a language of the knowledge ' \
                                    'base. semantic searches by meaning, where the helpdesk has it set up, and says how ' \
                                    'well the answers fit: for a question in the user\'s own words, or in another ' \
                                    'language than the knowledge base\'s.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next answers.'

  def self.available?
    ::KnowledgeBase.active.exists?
  end

  # Why the search by meaning cannot run, nil where it can. Available answers false for a switched-off feature and for a
  #   vector database that does not answer alike, so the ping is asked apart, last. During a rebuild the index would
  #   compare the query with vectors of another embedding model.
  def self.unready_state
    configuration = Service::AI::VectorDB::Embedding::Configuration.current

    return 'off' if configuration.nil? || !Service::AI::VectorDB::Available.execute(ping: false)
    return 'pending' if configuration != Service::AI::VectorDB::Embedding::Configuration.indexed

    'failed' if !Service::AI::VectorDB::Available.execute
  end

  def execute
    return search_result if argument(:cursor)

    Service::AI::Tool::Runtime::SearchCount.noted_result(search_result, run:)
  end

  private

  def search_result
    return Service::AI::Tool::Runtime::Result.error('not_found', 'This helpdesk has no knowledge base.') if knowledge_base.nil?
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', 'Give words to look for: a short question or a few words.') if !Service::AI::Tool::Search::QueryWords.words?(query)
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', NO_SYNTAX) if keyword_chosen? && !SearchIndexBackend.enabled? && Service::AI::Tool::Search::QueryWords.field?(query)
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this search. #{CURSOR_HINT} the best answers.") if offset.nil?
    return Service::AI::Tool::Runtime::Result.error('search_failed', failed_text) if found.keyword_search == 'failed' && found.hits.empty?

    Service::AI::Tool::Runtime::Result.ok(content, text:)
  end

  def knowledge_base
    @knowledge_base ||= ::KnowledgeBase.active.first
  end

  def query
    argument(:query).to_s.squish
  end

  def limit
    argument(:limit)
  end

  def offset
    cursor_offset
  end

  # The ranked answers a page needs: those before it, its own and one more, which says whether more follow.
  def wanted
    [offset + limit + 1, RANKED].min
  end

  def first_page?
    offset.zero?
  end

  def page
    @page ||= found.hits[offset, limit] || []
  end

  def more?
    found.hits.size > offset + limit
  end

  def content
    @content ||= {
      query:,
      mode:            found.mode,
      semantic_search: found.semantic_search,
      keyword_search:  found.keyword_search,
      coverage:        (found.coverage if first_page?),
      answers:         rows.map(&:content),
      has_more:        more?,
      next_cursor:     (next_cursor_at(offset + limit) if more?),
    }.compact
  end

  # Loaded once, so that the rows, the text and the verdict see the same answers.
  def found
    @found ||= keyword_chosen? ? search_by_words(nil) : search_by_meaning_or_words
  end

  def keyword_chosen?
    argument(:mode) == 'keyword'
  end

  def search_by_meaning_or_words
    state = unready_state
    return search_by_words(state) if state

    search_by_meaning || search_by_words('failed')
  end

  def unready_state
    self.class.unready_state
  end

  def search_by_meaning
    candidates = meaning_hits
    hits       = with_identifier_hits(candidates)

    Found.new(mode: 'semantic', semantic_search: 'ready', keyword_search: nil, coverage: verdict(candidates, hits), hits:)
  rescue AI::Provider::RequestError, AI::Provider::ResponseError, AI::VectorDB::Error => e
    Rails.logger.error "AI tool #{self.class.tool_name} searches by words, the search by meaning failed: #{e.class}: #{e.message}"
    nil
  end

  # The values of the embedding model the index was built with; none for a model nobody measured.
  def coverage
    return @coverage if defined?(@coverage)

    @coverage = Service::AI::Tool::SearchKnowledgeBase::Coverage.for(Service::AI::VectorDB::Embedding::Configuration.current&.dig(:model))
  end

  # One per answer, in the translation that matched best; every translation of an answer can match. Two at least,
  #   whatever the page, so that the verdict sees how far the best one stands out.
  def meaning_hits
    embedding = Service::AI::VectorDB::Embedding.execute(input: query)
    answers   = [wanted, 2].max

    Service::KnowledgeBase::Answer::SimilaritySearch
      .with_current_user(current_user)
      .execute(embedding:, limit: answers * [knowledge_base.kb_locales.count, 1].max, minimum_score: coverage&.listed || 0)
      .select { |result| readable?(result[:translation]) }
      .uniq { |result| result[:translation].answer_id }
      .first(answers)
      .map { |result| with_current_passage(result, ::Text::ContentCleanup.new(content: result[:translation].content&.body.to_s).cleanup) }
  end

  # The indexes catch up with an edit in a job. A passage the current text no longer holds is left out, so that the row
  #   shows the current text; the text is compared as the index converted it.
  def with_current_passage(hit, text)
    return hit if hit[:passage].blank? || text.squish.include?(hit[:passage].squish)

    hit.merge(passage: nil, outdated: true)
  end

  # An answer that holds an identifier of the query is listed on the first page even when its meaning is not close
  #   enough. The best answer by meaning keeps its place; the others share what the limit leaves, and those that do not
  #   fit any more follow on the next pages.
  def with_identifier_hits(hits)
    hits   = hits.map { |hit| hit.merge(contains: identifiers.find { |identifier| holds?(hit[:translation], identifier) }).compact }
    shown  = hits.first(limit)
    others = identifier_hits(except: shown.map { |hit| answer_id_of(hit) }, count: identifier_room(shown))
    first  = shown.first(limit - others.size) + others
    taken  = first.map { |hit| answer_id_of(hit) }

    first + hits.drop(limit - others.size).reject { |hit| taken.include?(answer_id_of(hit)) }
  end

  # The answers of a page depend on the limit, as the identifiers take their place among the first ones.
  def cursor_scope
    super.merge('limit' => limit)
  end

  def identifiers = @identifiers ||= Service::AI::Tool::SearchKnowledgeBase::Identifiers.in(query)

  # The answers the user may read that hold an identifier, newest first, one per answer. The database finds the
  #   identifier as a part of the text, so each answer is checked for the whole of it, as many as it takes: answers
  #   with longer identifiers that begin with it take no place, which a capped keyword search cannot promise.
  def identifier_hits(except:, count:)
    return [] if identifiers.empty? || count.zero?

    found = {}
    identifier_candidates(except:).in_batches(of: IDENTIFIER_BATCH, order: :desc) do |batch|
      batch.includes(:content).each do |translation|
        next if found.key?(translation.answer_id) || !readable?(translation)

        identifier = identifiers.find { |candidate| holds?(translation, candidate) }
        next if identifier.nil?

        found[translation.answer_id] = { translation:, passage: passage_at(translation, identifier), contains: identifier }
        return found.values if found.size == count
      end
    end

    found.values
  end

  # Internally or publicly published answers of the knowledge base that the user may see, as the search by meaning
  #   narrows them (Service::KnowledgeBase::Answer::SimilaritySearch).
  def identifier_candidates(except:)
    answers = ::KnowledgeBase::Answer
      .visible_to_user(current_user)
      .internal
      .joins(:category)
      .where(knowledge_base_categories: { knowledge_base_id: knowledge_base.id })
      .where.not(id: except)

    identifiers
      .map { |identifier| holding(identifier) }
      .reduce(:or)
      .where(answer_id: answers.select(:id))
  end

  # The database holds the text as HTML, where markup can stand anywhere in an identifier, as in
  #   "ERR-40<strong>32</strong>": it looks for the identifier in the text without its tags, and #holds? checks the
  #   text as it reads. A tag starts with a letter, so a title's "< 2.1.3" stays, as SearchKnowledgeBaseBackend.plain_text
  #   reads it.
  def holding(identifier)
    translations = ::KnowledgeBase::Answer::Translation
    title        = "#{translations.quoted_table_name}.title"
    body         = "#{::KnowledgeBase::Answer::Translation::Content.quoted_table_name}.body"

    translations
      .joins(:content)
      .where(
        "regexp_replace(#{title}, :tag, '', 'g') ILIKE :pattern OR regexp_replace(#{body}, :tag, '', 'g') ILIKE :pattern",
        tag:     '</?[[:alpha:]][^>]*>',
        pattern: "%#{translations.sanitize_sql_like(identifier)}%",
      )
  end

  def holds?(translation, identifier)
    text = "#{SearchKnowledgeBaseBackend.plain_text(translation.title)}\n#{translation.content&.body_text_only}"

    Service::AI::Tool::Search::WholeWord.in?(text, identifier)
  end

  def passage_at(translation, identifier)
    Service::AI::Tool::Output.passage_at(translation.content&.body_text_only.to_s, Service::AI::Tool::Search::WholeWord.pattern(identifier))
  end

  def identifier_room(hits)
    [hits.any? ? limit - 1 : limit, Service::AI::Tool::SearchKnowledgeBase::Identifiers::MAX].min
  end

  def answer_id_of(hit)
    hit[:translation].answer_id
  end

  # Judged on the answers found by meaning, before the limit or an identifier takes the place of one. A best answer
  #   edited since the index took it may no longer fit.
  def verdict(candidates, hits)
    return 'unknown' if coverage.nil?

    result = coverage.of(candidates.pluck(:score))
    return 'weak' if result == 'covered' && candidates.first[:outdated]

    result == 'none' && hits.any? { |hit| hit[:contains] } ? 'weak' : result
  end

  def search_by_words(semantic_search)
    words, keyword_search = word_hits_or_failure

    Found.new(mode: 'keyword', semantic_search:, keyword_search:, coverage: 'unknown', hits: with_identifier_hits(words.first(wanted)))
  end

  def word_hits_or_failure
    [word_hits(query_words), nil]
  rescue SearchIndexBackend::SearchFailedError => e
    Rails.logger.error "AI tool #{self.class.tool_name} found nothing by words, the search failed: #{e.message}"
    [[], 'failed']
  end

  # Where the model chose the search by words, the search by meaning is the other way; where it fell back to words, no
  #   way is left.
  def failed_text
    unready = found.semantic_search || unready_state

    return "The search by words failed. Search by meaning instead. #{NOT_SEARCHED}" if unready.nil?

    "The knowledge base could not be searched: #{UNREADY_TEXTS.fetch(unready)}, and the search by words failed. " \
      "#{NOT_SEARCHED} Tell the user that the knowledge base cannot be searched right now."
  end

  # Without Elasticsearch, the database looks for the query as it stands. A search by words the model chose takes the
  #   syntax as the knowledge base search box does; a question that falls back to words would read its "?" and ":" as
  #   syntax.
  def query_words
    return query if !SearchIndexBackend.enabled? || keyword_chosen?

    Service::AI::Tool::Search::QueryWords.without_syntax(query)
  end

  # As the desktop view searches, but only answers published internally or publicly, one row per answer in its best
  #   translation; the passage is what Elasticsearch highlighted, which the search without it does not.
  def word_hits(words)
    Service::KnowledgeBase::Search
      .with_current_user(current_user)
      .execute(query: words, knowledge_base:, entity: :answer, limit: KEYWORD_CANDIDATES, include_drafts_and_archived: false, raise_on_failure: true)
      .results
      .select { |result| readable?(result.translation) }
      .uniq { |result| result.item.id }
      .map { |result| with_current_passage({ translation: result.translation, passage: highlighted_passage(result) }, result.translation.content&.body_text_only.to_s) }
  end

  def highlighted_passage(result)
    result.body_preview.map(&:text).join if result.body_preview.any?(&:highlight)
  end

  # The best answers of the whole search come with their text, the others with the part that matched.
  def rows
    @rows ||= begin
      translations = page.pluck(:translation)
      ActiveRecord::Associations::Preloader.new(records: translations, associations: [:content, :answer, { kb_locale: :system_locale }]).call

      page.each_with_index.map { |hit, index| row_of(hit, offset + index < FULL_TEXTS ? TEXT_LENGTH : EXCERPT_LENGTH) }
    end
  end

  def row_of(hit, length)
    translation = hit[:translation]

    Service::AI::Tool::Output::KnowledgeBaseAnswer.part(
      translation,
      length:,
      passage:   hit[:passage],
      edited_at: (translation.edited_at if field_visible?(translation, :edited_at)),
      content:   { contains: hit[:contains] }.compact,
      facts:     [("contains #{hit[:contains]}" if hit[:contains])],
    )
  end

  def text
    header = AI::PromptText.xml_text([search_line, languages_line].join("\n"))
    return [header, no_match_text].join("\n") if found.mode == 'keyword' && found.hits.empty?

    [
      [header, (KEYWORD_FAILED if found.keyword_search), first_page? ? COVERAGE_TEXTS.fetch(found.coverage) : LATER_PAGE].compact.join("\n"),
      *rows.map(&:text),
      (READ_IN_FULL if rows.any? { |row| row.content[:truncated] }),
      ("More follow: call again with the same arguments and cursor \"#{content[:next_cursor]}\"." if more?),
    ].compact.join("\n\n")
  end

  # A search by meaning is suggested only where the model chose the words and it can run.
  def no_match_text
    found.semantic_search || unready_state ? NO_KEYWORD_MATCH : NO_CHOSEN_MATCH
  end

  def search_line
    "Knowledge base search for \"#{query}\", #{SEARCH_TEXTS.fetch(found.semantic_search || 'keyword')}"
  end

  # The model writes the words of a search by words in these languages.
  def languages_line
    "Knowledge base languages: #{languages.join(', ')}."
  end

  def languages
    knowledge_base.kb_locales.joins(:system_locale).reorder(primary: :desc, id: :asc).pluck('locales.locale')
  end
end
