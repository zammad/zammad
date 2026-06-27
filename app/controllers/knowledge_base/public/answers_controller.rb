# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Public::AnswersController < KnowledgeBase::Public::BaseController

  def show
    @category        = find_category(params[:category])
    @object          = find_answer(@category&.answers, params[:answer])
    @object_locales  = find_locales(@object)

    if @object.blank?
      render_alternative
      return
    end

    adjacent_answer = KnowledgeBase::AdjacentAnswer.new(@object.translation, user: current_user)

    @object_next     = adjacent_answer.next
    @object_previous = adjacent_answer.previous
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
