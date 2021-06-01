# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBaseBreadcrumbHelper
  def render_breadcrumb_if_needed(knowledge_base, object, alternative)
    objects = calculate_breadcrumb_path(object, alternative)

    return if objects.empty?

    render 'knowledge_base/public/breadcrumb',
           {
             objects:        objects,
             knowledge_base: knowledge_base
           }
  end

  def calculate_breadcrumb_path(object, alternative)
    objects = calculate_breadcrumb_to_category(object&.parent)

    last = if alternative.present? && alternative.translations.any?
             Translation.translate(system_locale_via_uri&.locale, 'Alternative translations')
           else
             object
           end

    objects + [last].compact
  end

  def calculate_breadcrumb_to_category(category)
    return [] if category.blank?

    output = [category]

    parent = category
    while (parent = find_category(parent&.parent_id))
      output << parent
    end

    output.compact.reverse
  end

  def breadcrumb_path_for(object, locale = params.fetch(:locale))
    case object
    when KnowledgeBase
      help_root_path(locale: locale)
    when KnowledgeBase::Category
      help_category_path(object.translation, locale: locale)
    when KnowledgeBase::Answer
      help_answer_path(object.category.translation, object.translation, locale: locale)
    end
  end

  def breadcrumb_text_for(object)
    case object
    when HasTranslations
      object.translation.title
    else
      object
    end
  end
end
