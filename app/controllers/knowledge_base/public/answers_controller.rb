# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Public::AnswersController < KnowledgeBase::Public::BaseController

  def show
    @category        = find_category(params[:category])
    @object          = find_answer(@category&.answers, params[:answer])
    @object_locales  = find_locales(@object)

    render_alternative if @object.blank?
  end

  private

  def render_alternative
    answers = @knowledge_base.answers.where(category: params[:category]).eager_load(translations: :kb_locale)

    @alternative = find_answer(answers, params[:answer], locale: false)

    raise ActiveRecord::RecordNotFound if !@alternative&.translations&.any?

    @object_locales = @alternative.translations.map { |x| x.kb_locale.system_locale }

    render 'knowledge_base/public/show_alternatives', locals: { name: 'Answer' }
  end
end
