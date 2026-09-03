# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Searches the knowledge base for the desktop view: answers and categories of one knowledge base,
# optionally narrowed to a category subtree, each with a preview of where the term was found.
#
# Only answers and categories are searched. The knowledge base node itself is deliberately left
# out — it is not something the result list offers to open. (A scoped search already drops it,
# because KnowledgeBase::Translation.apply_kb_scope returns none, but an unscoped one would not.)
#
# Returns the hits plus the batched per-category data the GraphQL types need to render them, in the
# same shape as Service::KnowledgeBase::CategoryContent — see Gql::Queries::KnowledgeBase::Search
# for where those batches are handed over.
class Service::KnowledgeBase::Search < Service::Base
  include Service::KnowledgeBase::Concerns::WalksCategoryTree

  requires_current_user!

  INDEXES = [
    ::KnowledgeBase::Answer::Translation.name,
    ::KnowledgeBase::Category::Translation.name,
  ].freeze

  # The whole permission-filtered list is materialised in Ruby and the connection pages over it in
  # memory, so the search needs a bound. At the frontend's page size of 30 this is roughly seven
  # pages — far past where anyone keeps paging — and a truncation is logged rather than silently
  # reported as a complete total.
  MAX_RESULTS = 200

  # Private Use Area code points. Elasticsearch's default is <em>…</em>, which cannot be told apart
  # from the same characters occurring in the body text; the body is indexed as plain text (see
  # KnowledgeBase::Answer::Translation::Content#search_index_attribute_lookup), so it can contain
  # literal angle brackets. These cannot, which is what lets #segments split on them unambiguously.
  HIGHLIGHT_START = "\u{E000}".freeze
  HIGHLIGHT_END   = "\u{E001}".freeze

  # One fragment per field, long enough to read as a preview, and no_match_size so an answer whose
  # title matched still comes with the opening of its body rather than nothing.
  HIGHLIGHT_OPTIONS = {
    pre_tags:            [HIGHLIGHT_START],
    post_tags:           [HIGHLIGHT_END],
    number_of_fragments: 1,
    fragment_size:       200,
    no_match_size:       200,
  }.freeze

  Output  = Struct.new(:results, :category_translations, :category_visibility, keyword_init: true)
  Result  = Struct.new(:item, :title_preview, :body_preview, :category_path, keyword_init: true)
  Segment = Struct.new(:text, :highlight, keyword_init: true)

  attr_reader :query, :knowledge_base, :scope, :locale

  # `scope` is the category to search within (its whole subtree), `locale` the resolved
  #   KnowledgeBase::Locale being browsed.
  def initialize(query:, knowledge_base:, scope: nil, locale: nil)
    @query          = query
    @knowledge_base = knowledge_base
    @scope          = scope
    @locale         = locale
  end

  def execute
    return empty if query.blank?

    hits = backend.search(query, user: current_user)

    log_truncation(hits)
    preheat(hits)

    results = hits.filter_map { |hit| result_for(hit) }

    Output.new(
      results:               results,
      category_translations: category_translations(results),
      category_visibility:   category_visibility(results),
    )
  end

  private

  def empty
    Output.new(results: [], category_translations: {}, category_visibility: {})
  end

  def backend
    SearchKnowledgeBaseBackend.new(
      knowledge_base:    knowledge_base,
      locale:            locale,
      scope:             scope,
      flavor:            flavor,
      index:             INDEXES,
      # Both are needed: SearchKnowledgeBaseBackend#options_apply_pagination only forwards a limit
      #   to Elasticsearch when an offset is given too, and without one Elasticsearch answers with
      #   its own default of ten hits.
      from:              0,
      limit:             MAX_RESULTS,
      highlight_enabled: true,
      highlight_options: HIGHLIGHT_OPTIONS,
    )
  end

  # Derived rather than hardcoded to :agent. SearchKnowledgeBaseBackend#use_internal_assets? is
  #   `flavor == :agent && granular_permissions?` with no role condition, so a user without any
  #   knowledge base permission would be filtered through the granular category grants — of which
  #   they have none — and see nothing, while KnowledgeBase::Answer.visible_to_user still lets them
  #   browse published content. Mapping :public through keeps search and browsing in agreement.
  #
  # A side effect is that such a user searches with the public field list and therefore without the
  #   title/tag weighting, which SearchKnowledgeBaseBackend applies to the agent flavor only so the
  #   public help site's ranking stays untouched.
  def flavor
    ::KnowledgeBase.access_for_user(current_user) == :public ? :public : :agent
  end

  # Permission filtering happens after the cap, so a search that was truncated can still come back
  #   shorter than MAX_RESULTS — this reports the cases it can see rather than none at all.
  def log_truncation(hits)
    return if hits.size < MAX_RESULTS

    Rails.logger.info { "Knowledge base search for #{query.inspect} hit the result cap of #{MAX_RESULTS}; totalCount is a lower bound." }
  end

  # Everything the result page needs, in a fixed number of queries rather than a few per hit. The
  #   answer's own translations are included because AnswerType resolves its `translation` from
  #   that collection, not from the translation the hit came from.
  def preheat(hits)
    grouped = hits.group_by { |hit| hit[:type] }.transform_values { |group| group.pluck(:id) }

    @answer_translations = ::KnowledgeBase::Answer::Translation
      .where(id: grouped[::KnowledgeBase::Answer::Translation.name])
      .includes(:content, answer: [{ translations: :kb_locale }, { category: :knowledge_base }])
      .index_by(&:id)

    @category_translations = ::KnowledgeBase::Category::Translation
      .where(id: grouped[::KnowledgeBase::Category::Translation.name])
      .includes(category: %i[parent knowledge_base])
      .index_by(&:id)
  end

  # nil for a hit whose record is gone: the search index can lag behind a deletion.
  def result_for(hit)
    case hit[:type]
    when ::KnowledgeBase::Answer::Translation.name
      translation = @answer_translations[hit[:id]]
      translation && answer_result(hit, translation)
    when ::KnowledgeBase::Category::Translation.name
      translation = @category_translations[hit[:id]]
      translation && category_result(hit, translation)
    end
  end

  def answer_result(hit, translation)
    Result.new(
      item:          translation.answer,
      title_preview: preview(hit, 'title', translation.title),
      body_preview:  preview(hit, 'content.body', translation.content&.body_excerpt),
      category_path: path_for(translation.answer.category_id),
    )
  end

  # A category has no body to preview, and its own title is the result — so the path is where it
  #   sits, i.e. its parent chain, mirroring the subtitle the legacy search list shows.
  def category_result(hit, translation)
    Result.new(
      item:          translation.category,
      title_preview: preview(hit, 'title', translation.title),
      body_preview:  [],
      category_path: path_for(translation.category.parent_id),
    )
  end

  # Root first, walked in the in-memory tree — one query for the knowledge base's categories
  #   instead of a recursive parent query per distinct category on the page.
  def path_for(category_id)
    trail_of(categories_by_id[category_id])
  end

  # Categories whose title is rendered: every hit that is a category, plus every category on a
  #   path. Resolved from one translation load, because #translation_preferred queries per call.
  def localized_categories(results)
    @localized_categories ||= (hit_categories(results) + results.flat_map(&:category_path)).uniq(&:id)
  end

  def hit_categories(results)
    @hit_categories ||= results.map(&:item).grep(::KnowledgeBase::Category).uniq(&:id)
  end

  # Preferred translation of every rendered category, keyed by category id: the browsed locale,
  #   then the primary locale, then any - resolved in one query for all of them.
  def category_translations(results)
    locale_id = locale&.id || primary_kb_locale_id
    return {} if locale_id.nil?

    ::KnowledgeBase::Category
      .preferred_translations_for(localized_categories(results).map { |category| [category.id, locale_id] })
      .transform_keys(&:first)
  end

  # Highest content visibility of the subtree of each category hit, in the browsed locale. Batched
  #   for the same reason as the titles above: CategoryType#visibility falls back to
  #   KnowledgeBase::Category#content_visibility, which walks the subtree with a recursive CTE once
  #   per publication state, per category. Only the hits need it — a path segment renders its title
  #   alone (Gql::Types::KnowledgeBase::Search::PathSegmentType).
  def category_visibility(results)
    hit_categories(results).to_h { |category| [category.id, content_visibility(category.id)] }
  end

  def primary_kb_locale_id
    @primary_kb_locale_id ||= knowledge_base.kb_locales.find_by(primary: true)&.id
  end

  # The highlighted fragment when Elasticsearch produced one, otherwise the plain text as a single
  #   unhighlighted segment — which is also the whole story on the SQL fallback, where there are no
  #   highlights at all.
  #
  # The index holds the texts HTML-escaped (the translations run them through `strip_tags` for the
  #   legacy consumers, which render fragments as markup), so a fragment reads `Law &amp; order`.
  #   The segments are plain text the client escapes itself, so undo that here — the fallback comes
  #   straight from the database and is not escaped.
  def preview(hit, field, fallback)
    fragment = hit.dig(:highlight, field)&.first

    return segments(unescape(fragment)) if fragment.present?
    return [] if fallback.blank?

    [Segment.new(text: fallback, highlight: false)]
  end

  # Splits a sentinel-tagged fragment into alternating plain and highlighted segments, so the
  #   client can render <mark> itself instead of being handed markup to inject.
  #
  # Empty runs are dropped, so adjacent highlights do not produce a blank segment between them, and
  #   a sentinel without its closing counterpart marks the rest of the fragment rather than raising.
  def segments(fragment)
    fragment.split(HIGHLIGHT_START).flat_map.with_index do |chunk, index|
      next plain(chunk) if index.zero?

      highlighted, _, rest = chunk.partition(HIGHLIGHT_END)

      marked(highlighted).concat(plain(rest))
    end
  end

  # Decoded by the same parser that escaped it on the way into the index (Rails strip_tags =
  #   Loofah = Nokogiri) so every entity it emits (`&amp;`, `&lt;`, `&gt;`, and `&nbsp;` for a
  #   non-breaking space, which CGI.unescapeHTML does not know) comes back as its character. The
  #   fragment carries no tags — they were stripped before indexing — and the highlight sentinels
  #   are private-use characters, untouched by it.
  def unescape(fragment)
    Nokogiri::HTML.fragment(fragment).text
  end

  def marked(text)
    text.empty? ? [] : [Segment.new(text: text, highlight: true)]
  end

  def plain(text)
    text.empty? ? [] : [Segment.new(text: text, highlight: false)]
  end
end
