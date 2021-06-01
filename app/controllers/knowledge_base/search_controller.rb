# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::SearchController < ApplicationController
  skip_before_action :verify_csrf_token
  prepend_before_action :authentication_check_only

  include KnowledgeBaseHelper
  include ActionView::Helpers::SanitizeHelper

  # POST /api/v1/knowledge_bases/search
  # knowledge_base_id, locale, flavor, index, limit, include_locale
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
      highlight_enabled: params[:highlight_enabled]
    )

    include_locale = params[:include_locale] && KnowledgeBase.with_multiple_locales_exists?

    result = search_backend.search params[:query], user: current_user

    if (exclude_ids = params[:exclude_ids]&.map(&:to_i))
      result.reject! { |meta| meta[:type] == params[:index] && exclude_ids.include?(meta[:id]) }
    end

    details = result.map { |item| public_item_details(item, include_locale) }

    render json: {
      result:  result,
      details: details,
    }
  end

  private

  def item_assets(meta)
    object = meta[:type].constantize.find(meta[:id])
    object.assets
  end

  def public_item_details(meta, include_locale)
    object = meta[:type].constantize.find(meta[:id])

    output = case object
             when KnowledgeBase::Answer::Translation
               public_item_details_answer(meta, object)
             when KnowledgeBase::Category::Translation
               public_item_details_category(meta, object)
             when KnowledgeBase::Translation
               public_item_details_base(meta, object)
             end

    if include_locale && (system_locale = object.kb_locale.system_locale)
      output[:title] += " (#{system_locale.name})"
    end

    output
  end

  def public_item_details_answer(meta, object)
    category_translation = object.answer.category.translation_preferred(object.kb_locale)
    path                 = help_answer_path(category_translation, object, locale: object.kb_locale.system_locale.locale)
    subtitle             = object.answer.category.self_with_parents.map { |c| strip_tags(c.translation_preferred(object.kb_locale).title) }.reverse
    subtitle = if subtitle.count <= 2
                 subtitle.join(' > ')
               else
                 subtitle.values_at(0, -1).join(' > .. > ')
               end

    url = case url_type
          when :public
            custom_path_if_needed(path, object.answer.category.knowledge_base)
          when :agent
            knowledge_base_answer_path(object.answer.category.knowledge_base, object.answer) + "?include_contents=#{object.id}"
          end

    {
      id:       object.id,
      type:     object.class.name,
      icon:     'knowledge-base-answer',
      date:     object.updated_at,
      url:      url,
      title:    meta.dig(:highlight, 'title')&.first || object.title,
      subtitle: subtitle,
      body:     meta.dig(:highlight, 'content.body')&.first || strip_tags(object.content.body).truncate(100)
    }
  end

  def public_item_details_category(meta, object)
    parent_category_translation = object.category.parent&.translation_preferred(object.kb_locale)
    path = help_category_path(object, locale: object.kb_locale.system_locale.locale)

    url = case url_type
          when :public
            custom_path_if_needed(path, object.category.knowledge_base)
          when :agent
            knowledge_base_category_path(object.category.knowledge_base, object.category)
          end

    {
      id:       object.id,
      type:     object.class.name,
      fontName: object.category.knowledge_base.iconset,
      date:     object.updated_at,
      url:      url,
      icon:     object.category.category_icon,
      subtitle: strip_tags(parent_category_translation&.title.presence),
      title:    meta.dig(:highlight, 'title')&.first || strip_tags(object.title)
    }
  end

  def public_item_details_base(meta, object)
    path = help_root_path(object.kb_locale.system_locale.locale)

    url = case url_type
          when :public
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
end
