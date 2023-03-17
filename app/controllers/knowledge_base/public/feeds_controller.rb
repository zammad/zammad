# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Public::FeedsController < KnowledgeBase::Public::BaseController
  before_action :ensure_response_format

  helper_method :build_original_url, :publishing_date, :updating_date

  def root
    @answers = @knowledge_base
      .answers
      .localed(system_locale_via_uri)
      .sorted_by_published
      .limit(10)

    @root_url = custom_path_if_needed(help_root_url, @knowledge_base, full: true)

    render template: 'knowledge_base/feeds/feed'
  end

  def category
    @category = find_category(params[:category])
    @answers  = @category
      .self_with_children_answers
      .localed(system_locale_via_uri)
      .sorted_by_published
      .limit(10)

    @root_url = custom_path_if_needed(help_category_url, @knowledge_base, full: true)

    render template: 'knowledge_base/feeds/feed'
  end

  private

  def ensure_response_format
    request.format = :atom
  end

  def build_original_url(answer)
    translation = answer.translations.first
    url         = help_answer_url(answer.category, translation, locale: translation.kb_locale.system_locale.locale)

    custom_path_if_needed url, @knowledge_base, full: true
  end

  def publishing_date(answer)
    answer.published_at
  end

  def updating_date(answer)
    [answer.published_at, answer.updated_at].compact.max
  end
end
