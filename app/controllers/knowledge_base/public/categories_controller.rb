# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Public::CategoriesController < KnowledgeBase::Public::BaseController
  skip_before_action :load_kb, only: :forward_root

  def index
    @categories     = categories_filter(@knowledge_base.categories.root)
    @object_locales = find_locales(@knowledge_base)

    raise ActiveRecord::RecordNotFound if !editor? && @categories.empty?
  end

  def show
    @object = find_category(params[:category])

    render_alternatives && return if !@object&.visible_content_for?(current_user)

    @categories     = categories_filter(@object.children)
    @object_locales = find_locales(@object)

    @answers = @object
               .answers
               .localed(system_locale_via_uri)
               .check_published_unless_editor(current_user)
               .sorted

    render :index
  end

  def forward_root
    knowledge_base = KnowledgeBase
                     .check_active_unless_editor(current_user)
                     .first!

    primary_locale = KnowledgeBase::Locale
                     .system_with_kb_locales(knowledge_base)
                     .where(knowledge_base_locales: { primary: true })
                     .first!

    path = help_root_path(locale: primary_locale.locale)

    redirect_to custom_path_if_needed(path, knowledge_base, full: true)
  end

  private

  def render_alternatives
    @page_title_error = :alternatives

    @object = nil

    @alternative = @knowledge_base
                   .categories
                   .eager_load(translations: :kb_locale)
                   .find_by(id: params[:category])

    if !@alternative&.translations&.any? || !@alternative&.visible_content_for?(current_user)
      raise ActiveRecord::RecordNotFound
    end

    @object_locales = @alternative.translations.map(&:kb_locale).map(&:system_locale)

    render 'knowledge_base/public/show_alternatives', locals: { name: 'Category' }
  end
end
