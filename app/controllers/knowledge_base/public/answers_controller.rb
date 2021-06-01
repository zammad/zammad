# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Public::AnswersController < KnowledgeBase::Public::BaseController

  def show
    @category        = find_category(params[:category])
    @object          = find_answer(@category&.answers, params[:answer])
    @object_locales  = find_locales(@object)

    render_alternative if @object.blank?
  end

  private

  def render_alternative
    @alternative = @knowledge_base
                   .answers
                   .eager_load(translations: :kb_locale)
                   .check_published_unless_editor(current_user)
                   .find_by(id: params[:answer])

    raise ActiveRecord::RecordNotFound if !@alternative&.translations&.any?

    @object_locales = @alternative.translations.map(&:kb_locale).map(&:system_locale)

    render 'knowledge_base/public/show_alternatives', locals: { name: 'Answer' }
  end
end
