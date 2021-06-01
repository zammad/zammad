# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SearchKnowledgeBaseBackend
  attr_reader :knowledge_base

  # @param [Hash] params the paramsused to initialize search instance
  # @option params [KnowledgeBase, <KnowledgeBase>] :knowledge_base (nil) knowledge base instance
  # @option params [KnowledgeBase::Locale, <KnowledgeBase::Locale>, String] :locale (nil) KB Locale or string identifier
  # @option params [KnowledgeBase::Category] :scope (nil) optional search scope
  # @option params [Symbol]  :flavor (:public) agent or public to indicate source and narrow down to internal or public answers accordingly
  # @option params [String, Array<String>] :index (nil) indexes to limit search to, searches all indexes if nil
  # @option params [Boolean] :highlight_enabled (true) highlight matching text

  def initialize(params)
    @params = params.compact

    prepare_scope_ids
  end

  def search(query, user: nil)
    raw_results = if SearchIndexBackend.enabled?
                    SearchIndexBackend
                      .search(query, indexes, options)
                      .map do |hash|
                        hash[:id] = hash[:id].to_i
                        hash
                      end
                  else
                    search_fallback(query, indexes, { user: user })
                  end

    if (limit = @params.fetch(:limit, nil))
      raw_results = raw_results[0, limit]
    end

    filter_results raw_results, user
  end

  def search_fallback(query, indexes, options)
    indexes
      .map { |index| search_fallback_for_index(query, index, options) }
      .flatten
  end

  def search_fallback_for_index(query, index, options)
    index
      .constantize
      .search_fallback("%#{query}%", @cached_scope_ids, options: options)
      .where(kb_locale: kb_locales)
      .pluck(:id)
      .map { |id| { id: id, type: index } }
  end

  def filter_results(raw_results, user)
    raw_results
      .group_by { |result| result[:type] }
      .map      { |group_name, grouped_results| filter_type(group_name, grouped_results, user) }
      .flatten
  end

  def filter_type(type, grouped_results, user)
    translation_ids = translation_ids_for_type(type, user)

    if !translation_ids
      return []
    end

    grouped_results.select { |result| translation_ids&.include? result[:id].to_i }
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

    scope = if user&.permissions?('knowledge_base.editor')
              scope
            elsif user&.permissions?('knowledge_base.reader') && flavor == :agent
              scope.internal
            else
              scope.published
            end

    flatten_translation_ids(scope)
  end

  def translation_ids_for_categories(user)
    scope = KnowledgeBase::Category.where knowledge_base_id: knowledge_bases

    if user&.permissions?('knowledge_base.editor')
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

  def options
    output = {
      query_extension: {
        bool: {
          must: [ { terms: { kb_locale_id: kb_locale_ids } } ]
        }
      }
    }

    if @params.fetch(:highlight_enabled, true)
      output[:highlight_fields_by_indexes] = {
        'KnowledgeBase::Answer::Translation':   %w[title content.body attachment.content],
        'KnowledgeBase::Category::Translation': %w[title],
        'KnowledgeBase::Translation':           %w[title]
      }
    end

    if @params.fetch(:scope, nil)
      scope = { terms: { scope_id: @cached_scope_ids } }

      output[:query_extension][:bool][:must].push scope
    end

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

    translation.category.send("#{visibility}_content?", translation.kb_locale)
  end

  def prepare_scope_ids
    return if !@params.key? :scope

    @cached_scope_ids = @params.fetch(:scope).self_with_children_ids
  end
end
