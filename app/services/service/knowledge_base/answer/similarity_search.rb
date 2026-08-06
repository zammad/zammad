# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Performs a vector similarity search for knowledge base answers from a query embedding and returns
# the matching answer translations with their relevance score, ordered best-first. Permissions
# mirror the normal knowledge base search (KnowledgeBase::Answer::Translation::Search): the visible
# answer ids are resolved up front (visible_to_user, which encodes granular category access and the
# publish/archive time window) and passed as a filter on the documents' metadata.answer_id, so the
# search never returns answers the user is not allowed to see (rather than dropping them afterwards).
# By default only internally visible answers are searched, so drafts and archived ones are no
# suggestion for answering a ticket; `include_drafts_and_archived` takes in those two states as well,
# as far as the user may see them (knowledge base editors, and granular editor categories) — for
# deciding whether an answer already covers a topic, an unfinished or retired one counts too.
# Users without any knowledge base permission are limited to published answers, which they can read
# on the public help site.
# Locale restriction is optional (off by default) and applied in the query, so it does not eat into
# the limit.
class Service::KnowledgeBase::Answer::SimilaritySearch < Service::Base
  requires_current_user!

  DEFAULT_LIMIT = 3

  # Request more candidates than the limit: one answer is indexed as several chunks (deduplicated to
  # the best score below) and some hits get dropped by the score floor. Permission and locale
  # filtering already happen in the query, so they do not eat into this budget. A small margin is
  # enough for typical (1–few chunk) answers; raise it if chunk-heavy answers under-fill the limit.
  CANDIDATE_FACTOR = 6

  # Fallback for the configurable relevance floor below, for the case the setting holds no value.
  DEFAULT_RELEVANCE_SCORE = 86

  attr_reader :embedding, :limit, :locale, :include_drafts_and_archived

  def initialize(embedding:, limit: DEFAULT_LIMIT, locale: nil, include_drafts_and_archived: false)
    @embedding                   = embedding
    @limit                       = limit
    @locale                      = locale
    @include_drafts_and_archived = include_drafts_and_archived
  end

  def execute
    return [] if embedding.blank?

    visible_answer_ids = visible_answer_ids_for_user
    return [] if visible_answer_ids.blank?

    hits = search(visible_answer_ids)
    return [] if hits.blank?

    build_results(hits)
  end

  private

  def search(visible_answer_ids)
    filter = {
      object_name:          'KnowledgeBase::Answer::Translation',
      'metadata.answer_id': visible_answer_ids,
    }
    filter[:'metadata.locale'] = locale if locale.present?

    Service::AI::VectorDB::SimilaritySearch
      .execute(embedding:, k: limit * CANDIDATE_FACTOR, filter:)
      &.dig('hits', 'hits') || []
  end

  # The answers the user is allowed to see, identical to the regular knowledge base search
  # (KnowledgeBase::Answer::Translation::Search#search_answer_ids_for_user), narrowed to the
  # internally visible ones unless drafts and archived ones were requested as well, and minus the
  # ones in a category excluded from the vector index.
  #
  # Excluding a category only stops *future* indexing; the documents its answers already have stay
  # in the index until each record is touched or the index is rebuilt. Without this filter those
  # orphans keep surfacing as suggestions, so the exclusion is enforced here too rather than trusted
  # to the index being in sync.
  def visible_answer_ids_for_user
    scope = ::KnowledgeBase::Answer.visible_to_user(current_user)

    # `internal` covers both internally and publicly published answers, so it drops exactly the
    # states an answer is not usable in: draft and archived.
    scope = scope.internal if !include_drafts_and_archived

    scope
      .in_vector_indexable_category
      .pluck(:id)
  end

  # Returns ordered (best-first) `{ translation:, score: }` hashes.
  #
  # TODO(PoC): the raw similarity score is surfaced to the frontend for debugging/calibration. Before
  # this ships, decide how (or whether) to expose it — mxbai-embed-large has a high baseline so the
  # raw cosine-derived value reads uniformly high; a normalised relevance would be more meaningful.
  def build_results(hits)
    scores = best_scores_per_translation(hits)

    translations_for(scores.keys)
      .sort_by { |translation| -scores[translation.id] }
      .first(limit)
      .map { |translation| { translation:, score: scores[translation.id] } }
  end

  # Minimum relevance to surface a result. A vector search always returns its nearest neighbours, so
  # without a floor we would always show something, even for unrelated tickets. Elasticsearch maps
  # cosine similarity to (1 + cos) / 2 in 0..1 (so ~0.5 means "unrelated"), while admins configure
  # the threshold in percent — hence the conversion.
  def minimum_score
    @minimum_score ||= begin
      configured = Setting.get('ai_assistance_kb_answer_suggestions_relevance_score')

      (configured.presence || DEFAULT_RELEVANCE_SCORE).to_i / 100.0
    end
  end

  # Multiple chunks of the same translation can match; keep the best score per translation and drop
  # anything below the relevance floor.
  def best_scores_per_translation(hits)
    hits.each_with_object({}) do |hit, memo|
      score = hit['_score'].to_f
      next if score < minimum_score

      id = hit.dig('_source', 'object_id').to_i

      memo[id] = score if !memo.key?(id) || memo[id] < score
    end
  end

  def translations_for(translation_ids)
    return [] if translation_ids.blank?

    ::KnowledgeBase::Answer::Translation
      .where(id: translation_ids)
      .includes(:answer, :content, :kb_locale)
      .to_a
  end
end
