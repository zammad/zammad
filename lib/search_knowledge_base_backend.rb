# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SearchKnowledgeBaseBackend
  attr_reader :knowledge_base

  # @param [Hash] params the paramsused to initialize search instance
  # @option params [KnowledgeBase, <KnowledgeBase>] :knowledge_base (nil) knowledge base instance
  # @option params [KnowledgeBase::Locale, <KnowledgeBase::Locale>, String] :locale (nil) KB Locale or string identifier
  # @option params [KnowledgeBase::Category] :scope (nil) optional search scope
  # @option params [Symbol]  :flavor (:public) agent or public to indicate source and narrow down to internal or public answers accordingly
  # @option params [String, Array<String>] :index (nil) indexes to limit search to, searches all indexes if nil
  # @option params [Integer] :limit per page param for paginatin
  # @option params [Boolean] :highlight_enabled (true) highlight matching text
  # @option params [Hash] :highlight_options (nil) Elasticsearch highlight settings (pre_tags, post_tags,
  #   fragment_size, number_of_fragments, no_match_size, ...) applied to every highlighted field.
  #   Without it Elasticsearch's defaults apply, i.e. up to five 100 character <em> marked fragments.
  # @option params [Hash<String=>String>, Hash<Symbol=>Symbol>] :order_by hash with column => asc/desc

  def initialize(params)
    @params = params.compact

    prepare_scope_ids
  end

  def use_internal_assets?
    flavor == :agent && KnowledgeBase.granular_permissions?
  end

  def search(query, user: nil, pagination: nil)
    if use_internal_assets? # cache for later use
      @granular_permissions_handler = KnowledgeBase::InternalAssets.new(user)
    end

    raw_results = raw_results(query, pagination: pagination)

    filtered = filter_results raw_results, user

    if pagination
      filtered = filtered.slice pagination.offset, pagination.limit
    elsif @params[:limit]
      filtered = filtered.slice 0, @params[:limit]
    end

    filtered
  end

  def search_fallback(query, indexes)
    indexes.flat_map { |index| search_fallback_for_index(query, index) }
  end

  def search_fallback_for_index(query, index)
    index
      .constantize
      .search_sql_text_fallback("%#{query}%")
      .apply_kb_scope(@cached_scope_ids)
      .where(kb_locale: kb_locales)
      .reorder(**search_fallback_order)
      .pluck(:id)
      .map { |id| { id: id, type: index } }
  end

  def search_fallback_order
    @params[:order_by].presence || { updated_at: :desc }
  end

  def raw_results(query, pagination: nil)
    return search_fallback(query, indexes) if !SearchIndexBackend.enabled?

    results = SearchIndexBackend
      .search(query, indexes, options(query, pagination: pagination))
      .map do |hash|
        hash[:id] = hash[:id].to_i
        hash
      end

    sort_by_relevance results
  end

  # Elasticsearch is asked once per index and the responses are concatenated
  #   (SearchIndexBackend.search), so the combined list arrives grouped by index instead of by
  #   relevance. Merge it back into a single ranking, which is what makes answers and categories
  #   interleave.
  #
  # Those scores come from separate requests over separate indexes, and the term statistics behind
  #   them are per index — so they are approximately comparable, not a precise cross-index ranking.
  #   Good enough to interleave the two result kinds; do not read more into the order than that.
  #
  # An explicit :order_by is left alone: Elasticsearch already sorted by it, and the legacy REST
  #   controller relies on that (it pins updated_at desc).
  def sort_by_relevance(results)
    return results if @params[:order_by].present?

    # sort_by is not stable, so the original position is the tie-breaker — otherwise equally
    #   scored hits would shuffle between two identical searches.
    results
      .each_with_index
      .sort_by { |result, position| [-(result[:score] || 0), position] }
      .map(&:first)
  end

  # Drops hits the user may not see. Deliberately order-preserving: #raw_results hands over one
  #   merged relevance ranking, and grouping by type here — as this did before — would hand back
  #   all answers followed by all categories, destroying it.
  #
  # The permitted ids are still resolved once per type, not once per hit.
  def filter_results(raw_results, user)
    permitted_ids = raw_results
      .map { |result| result[:type] }
      .uniq
      .index_with { |type| translation_ids_for_type(type, user)&.to_set(&:to_i) }

    raw_results.select { |result| permitted_ids[result[:type]]&.include?(result[:id].to_i) }
  end

  def translation_ids_for_type(type, user)
    case type
    when KnowledgeBase::Answer::Translation.name
      translation_ids_for_answers(user)
    when KnowledgeBase::Category::Translation.name
      translation_ids_for_categories(user)
    when KnowledgeBase::Translation.name
      translation_ids_for_kbs(user)
    end
  end

  def translation_ids_for_answers(user)
    scope = KnowledgeBase::Answer
      .joins(:category)
      .where(knowledge_base_categories: { knowledge_base_id: knowledge_bases })
      .then do |relation|
        if use_internal_assets? # cache for later use
          relation.where(id: @granular_permissions_handler.all_answer_ids)
        elsif user&.permissions?('knowledge_base.editor')
          relation
        elsif user&.permissions?('knowledge_base.reader') && flavor == :agent
          relation.internal
        else
          relation.published
        end
      end

    flatten_translation_ids(scope)
  end

  def translation_ids_for_categories(user)
    scope = KnowledgeBase::Category.where(knowledge_base_id: knowledge_bases)

    if use_internal_assets?
      flatten_translation_ids scope.where(id: @granular_permissions_handler.all_category_ids)
    elsif user&.permissions?('knowledge_base.editor')
      flatten_translation_ids scope
    elsif user&.permissions?('knowledge_base.reader') && flavor == :agent
      flatten_answer_translation_ids(scope, :internal)
    else
      flatten_answer_translation_ids(scope, :public)
    end
  end

  def translation_ids_for_kbs(_user)
    flatten_translation_ids KnowledgeBase.active.where(id: knowledge_bases)
  end

  def indexes
    return Array(@params.fetch(:index)) if @params.key?(:index)

    %w[
      KnowledgeBase::Answer::Translation
      KnowledgeBase::Category::Translation
      KnowledgeBase::Translation
    ]
  end

  def kb_locales
    @kb_locales ||= begin
      case @params.fetch(:locale, nil)
      when KnowledgeBase::Locale
        Array(@params.fetch(:locale))
      when String
        KnowledgeBase::Locale
          .joins(:system_locale)
          .where(knowledge_base_id: knowledge_bases, locales: { locale: @params.fetch(:locale) })
      else
        KnowledgeBase::Locale
          .where(knowledge_base_id: knowledge_bases)
      end
    end
  end

  def kb_locales_in(knowledge_base_id)
    @kb_locales_in ||= {}
    @kb_locales_in[knowledge_base_id] ||= @kb_locales.select { |locale| locale.knowledge_base_id == knowledge_base_id }
  end

  def kb_locale_ids
    @kb_locale_ids ||= kb_locales.pluck(:id)
  end

  def knowledge_bases
    @knowledge_bases ||= begin
      if @params.key? :knowledge_base
        Array(@params.fetch(:knowledge_base))
      else
        KnowledgeBase.active
      end
    end
  end

  def flavor
    @params.fetch(:flavor, :public).to_sym
  end

  def base_options
    {
      query_extension: {
        bool: {
          must: [ { terms: { kb_locale_id: kb_locale_ids } } ]
        }
      }
    }
  end

  def options_apply_query_fields(hash)
    return if flavor == :agent

    hash[:query_fields_by_indexes] = {
      'KnowledgeBase::Answer::Translation':   %w[title content.body attachment.content tags],
      'KnowledgeBase::Category::Translation': %w[title],
      'KnowledgeBase::Translation':           %w[title]
    }
  end

  def options_apply_highlight(hash)
    return if !@params.fetch(:highlight_enabled, true)

    hash[:highlight_fields_by_indexes] = {
      'KnowledgeBase::Answer::Translation':   %w[title content.body tags],
      'KnowledgeBase::Category::Translation': %w[title],
      'KnowledgeBase::Translation':           %w[title]
    }

    # Opt-in rather than a new default: the legacy knowledge base search dropdown and the public
    #   help site render these fragments as raw HTML, so they need Elasticsearch's <em> defaults to
    #   keep working. Only callers that parse the fragments themselves pass their own settings.
    return if @params[:highlight_options].blank?

    hash[:highlight_options] = @params[:highlight_options]
  end

  def options_apply_scope(hash)
    return if !@params.fetch(:scope, nil)

    hash[:query_extension][:bool][:must].push({ terms: { scope_id: @cached_scope_ids } })
  end

  def options_apply_pagination(hash, pagination)
    if @params[:from] && @params[:limit]
      hash[:from]  = @params[:from]
      hash[:limit] = @params[:limit]
    elsif pagination
      hash[:from]  = 0
      hash[:limit] = pagination.limit * 99
    end
  end

  def options_apply_order(hash)
    return if @params[:order_by].blank?

    hash[:sort_by]  = @params[:order_by].keys
    hash[:order_by] = @params[:order_by].values
  end

  def options_apply_fulltext(hash)
    hash[:fulltext] = true
  end

  # Only needed to merge the per index responses into one ranking, which #sort_by_relevance skips
  #   when an explicit :order_by already decided the order.
  def options_apply_score(hash)
    return if @params[:order_by].present?

    hash[:with_score] = true
  end

  # Weigh a hit in the title or the tags above one in the body, so the ranking matches what a
  #   reader expects. Expressed as a scoring-only `should` beside the existing `must` — with a
  #   `must` present Elasticsearch requires none of the `should` clauses to match, so they can only
  #   add score, never widen or narrow the result set.
  #
  # Not done by putting `title^3 tags^2` into the query_string's `fields`, which is the obvious
  #   alternative: `fields` replaces the index default fields, so it also narrows which documents
  #   an *unqualified* term can match at all. (Explicit `field:value` terms would keep working —
  #   the public flavor sets `fields` and its shortcut queries match fine — but silently changing
  #   what a plain search finds is a bigger change than reordering it.)
  #
  # match_bool_prefix, not match: SearchIndexBackend.append_wildcard_to_simple_query turns the
  #   search into a prefix query, so the debounced search-as-you-type sends partial words. A plain
  #   `match` would tokenize `xyloph` and find nothing, leaving the weighting silently inactive for
  #   exactly the case it exists for.
  #
  # Agent flavor only: the public help site keeps its current ranking, and the legacy agent widget
  #   pins its own :order_by, so neither of them changes. The knowledge base suggestions in the
  #   ticket article composer (Gql::Queries::KnowledgeBase::Answer::Suggestions) are agent flavor
  #   without an :order_by, so they do pick the weighting up — intentionally, it is the same
  #   "a title hit is a better hit" rule.
  def options_apply_boost(hash, query)
    return if flavor != :agent
    return if query.blank?

    # A field qualified query (publication_state:draft, created_at:>now-14d, ...) is a filter, not
    #   a relevance search — append_wildcard_to_simple_query skips those on the same test, and
    #   there is nothing meaningful to weigh.
    return if query.include?(':')

    hash[:query_extension][:bool][:should] = [
      { match_bool_prefix: { title: { query: query, boost: 3 } } },
      { match_bool_prefix: { tags: { query: query, boost: 2 } } },
    ]
  end

  def options(query, pagination: nil)
    output = base_options

    options_apply_query_fields(output)
    options_apply_boost(output, query)
    options_apply_score(output)
    options_apply_highlight(output)
    options_apply_scope(output)
    options_apply_pagination(output, pagination)
    options_apply_order(output)
    options_apply_fulltext(output)

    output
  end

  def flatten_translation_ids(collection)
    collection
      .eager_load(:translations)
      .map { |elem| elem.translations.pluck(:id) }
      .flatten
  end

  def flatten_answer_translation_ids(collection, visibility)
    collection
      .eager_load(:translations)
      .map { |elem| visible_category_translation_ids(elem, visibility) }
      .flatten
  end

  def visible_category_translation_ids(category, visibility)
    category
      .translations
      .to_a
      .select { |elem| visible_translation?(elem, visibility) }
      .pluck(:id)
  end

  def visible_translation?(translation, visibility)
    if kb_locales_in(translation.category.knowledge_base_id).exclude?(translation.kb_locale)
      return false
    end

    translation.category.send(:"#{visibility}_content?", translation.kb_locale)
  end

  def prepare_scope_ids
    return if !@params.key? :scope

    @cached_scope_ids = @params.fetch(:scope).self_with_children_ids
  end
end
