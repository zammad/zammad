# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Public::FeedsController < KnowledgeBase::Public::BaseController
  before_action :ensure_response_format
  before_action :set_feed_url

  helper_method :build_original_url, :publishing_date, :updating_date

  def root
    @answers = @knowledge_base
      .answers
      .sorted_by_published(system_locale_via_uri)
      .limit(10)

    @root_url = custom_path_if_needed(help_root_path, @knowledge_base, full: true)

    render template: 'knowledge_base/feeds/feed'
  end

  def category
    @category = find_category(params[:category])
    @answers  = @category
      .self_with_children_answers
      .sorted_by_published(system_locale_via_uri)
      .limit(10)

    @root_url = custom_path_if_needed(help_category_path, @knowledge_base, full: true)

    render template: 'knowledge_base/feeds/feed'
  end

  private

  def ensure_response_format
    request.format = :atom
  end

  # The feed's own URL, rewritten for a custom address, drives the self link and
  # Atom id (see the feed template) so the internal /help mount point never leaks.
  def set_feed_url
    @feed_url = custom_path_if_needed(request.path, @knowledge_base, full: true)
  end

  def build_original_url(answer)
    translation = answer.translations.first
    url         = help_answer_path(answer.category, translation, locale: translation.kb_locale.system_locale.locale)

    custom_path_if_needed url, @knowledge_base, full: true
  end

  def publishing_date(answer)
    answer.published_at
  end

  def updating_date(answer)
    [answer.published_at, answer.updated_at].compact.max
  end
end
