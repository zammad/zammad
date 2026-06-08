# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::SearchController < ApplicationController
  skip_before_action :verify_csrf_token
  prepend_before_action :authentication_check_only

  include KnowledgeBaseHelper
  include ActionView::Helpers::SanitizeHelper
  include CanPaginate

  # POST /api/v1/knowledge_bases/search
  # knowledge_base_id, locale, flavor, index, page, per_page, limit, include_locale
  def search
    knowledge_base = KnowledgeBase
                     .active
                     .find_by id: params[:knowledge_base_id]

    kb_locale = knowledge_base
                &.kb_locales
                &.joins(:system_locale)
                &.find_by(locales: { locale: params[:locale] })

    scope = knowledge_base
              &.categories
              &.find_by(id: params[:scope_id])

    search_backend = SearchKnowledgeBaseBackend.new(
      knowledge_base:    knowledge_base,
      locale:            kb_locale,
      scope:             scope,
      flavor:            params[:flavor],
      index:             params[:index],
      limit:             params[:limit],
      highlight_enabled: params[:highlight_enabled],
      order_by:          { updated_at: :desc }
    )

    include_locale = params[:include_locale] && KnowledgeBase.with_multiple_locales_exists?

    result = search_backend.search params[:query], user: current_user, pagination: pagination

    if (exclude_ids = params[:exclude_ids]&.map(&:to_i))
      result.reject! { |meta| meta[:type] == params[:index] && exclude_ids.include?(meta[:id]) }
    end

    preheat_cache(result)

    details = result.map { |item| public_item_details(item, include_locale) }

    render json: {
      result:  result,
      details: details,
    }
  end

  private

  def public_item_details(meta, include_locale)
    object = get_prefetched_object(meta[:type], meta[:id])

    output = case object
             when KnowledgeBase::Answer::Translation
               public_item_details_answer(meta, object)
             when KnowledgeBase::Category::Translation
               public_item_details_category(meta, object)
             when KnowledgeBase::Translation
               public_item_details_base(meta, object)
             end

    if include_locale && (system_locale = object.kb_locale.system_locale)
      output[:title] += " (#{system_locale.locale.upcase})"
    end

    output
  end

  def public_item_details_answer(meta, object)
    url = case url_type
          when :public
            category_translation = get_prefetched_category_translation(object.answer.category, object.kb_locale)
            path                 = help_answer_path(category_translation, object, locale: object.kb_locale.system_locale.locale)

            custom_path_if_needed(path, object.answer.category.knowledge_base)
          when :agent
            knowledge_base_answer_path(object.answer.category.knowledge_base, object.answer) + "?include_contents=#{object.id}"
          end

    hash = {
      id:    object.id,
      type:  object.class.name,
      icon:  'knowledge-base-answer',
      date:  object.updated_at,
      url:   url,
      title: meta.dig(:highlight, 'title')&.first || object.title,
      body:  strip_repeating_whitespace(meta.dig(:highlight, 'content.body')&.first ||
                                        object.content.body_text_only.truncate(100))
    }

    if params[:include_tags]
      hash[:tags] = object.answer.tag_list
    end

    if params[:include_subtitle]
      hash[:subtitle] = get_answer_categories_path(object.answer.category, object.kb_locale)
    end

    hash
  end

  def public_item_details_category(meta, object)
    url = case url_type
          when :public
            path = help_category_path(object, locale: object.kb_locale.system_locale.locale)

            custom_path_if_needed(path, object.category.knowledge_base)
          when :agent
            knowledge_base_category_path(object.category.knowledge_base, object.category)
          end

    hash = {
      id:       object.id,
      type:     object.class.name,
      fontName: object.category.knowledge_base.iconset,
      date:     object.updated_at,
      url:      url,
      icon:     object.category.category_icon,
      title:    meta.dig(:highlight, 'title')&.first || strip_tags(object.title)
    }

    if params[:include_subtitle]
      parent_category_translation = get_prefetched_category_translation(object.category.parent, object.kb_locale)

      hash[:subtitle] = strip_tags(parent_category_translation&.title.presence)
    end

    hash
  end

  def public_item_details_base(meta, object)
    url = case url_type
          when :public
            path = help_root_path(object.kb_locale.system_locale.locale)

            custom_path_if_needed(path, object.knowledge_base)
          when :agent
            knowledge_base_path(object.knowledge_base)
          end

    {
      id:    object.id,
      type:  object.class.name,
      icon:  'knowledge-base',
      date:  object.updated_at,
      url:   url,
      title: meta.dig(:highlight, 'title')&.first || strip_tags(object.title)
    }
  end

  def url_type
    params[:url_type]&.to_sym || :public
  end

  def get_answer_categories_path(category, kb_locale)
    @answer_categories_path_cache ||= {}

    cache_key = "#{category.id}_#{kb_locale.id}"

    if @answer_categories_path_cache.key?(cache_key)
      return @answer_categories_path_cache[cache_key]
    end

    categories = category
      .self_with_parents
      .map { strip_tags(get_prefetched_category_translation(it, kb_locale).title) }
      .reverse

    path = if categories.count <= 2
             categories.join(' > ')
           else
             categories.values_at(0, -1).join(' > .. > ')
           end

    @answer_categories_path_cache[cache_key] = path
  end

  def preheat_cache(result)
    grouped_result = result
      .group_by { it[:type] }
      .transform_values { it.map { it[:id] } }

    @cache = {}
    @cache['KnowledgeBase::Translation'] = KnowledgeBase::Translation
      .includes(:knowledge_base, kb_locale: :system_locale)
      .where(id: grouped_result['KnowledgeBase::Translation'])
      .index_by(&:id)

    @cache['KnowledgeBase::Category::Translation'] = KnowledgeBase::Category::Translation
      .includes(category: %i[parent knowledge_base], kb_locale: :system_locale)
      .where(id: grouped_result['KnowledgeBase::Category::Translation'])
      .index_by(&:id)

    @cache['KnowledgeBase::Answer::Translation'] = KnowledgeBase::Answer::Translation
      .includes(:content, answer: { category: :knowledge_base }, kb_locale: :system_locale)
      .where(id: grouped_result['KnowledgeBase::Answer::Translation'])
      .index_by(&:id)
  end

  def get_prefetched_object(type, id)
    @cache.dig(type, id)
  end

  def get_prefetched_category_translation(category, kb_locale)
    return nil if category.nil?

    @category_translations_cache ||= {}

    cache_key = "#{category.id}_#{kb_locale.id}"

    if @category_translations_cache.key?(cache_key)
      return @category_translations_cache[cache_key]
    end

    translation = category.translation_preferred(kb_locale)

    @category_translations_cache[cache_key] = translation
  end

  def strip_repeating_whitespace(input)
    input.gsub(%r{\s+}, ' ')
  end
end
