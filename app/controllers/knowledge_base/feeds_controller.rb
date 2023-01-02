# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::FeedsController < KnowledgeBase::BaseController
  ITEMS_IN_FEED = 10

  prepend_before_action { authorize! }
  skip_before_action :authentication_check
  prepend_before_action -> { authentication_check_only }, only: %i[root category]

  before_action :ensure_response_format
  before_action :fetch_knowledge_base

  helper_method :build_original_url, :publishing_date, :updating_date

  def root
    scope = if KnowledgeBase.granular_permissions?
              granular_scope
            else
              @knowledge_base.answers
            end

    @answers = scope
      .localed(@locale)
      .sorted_by_internally_published
      .limit(ITEMS_IN_FEED)

    render :feed
  end

  def category
    @category = KnowledgeBase::Category.where(knowledge_base_id: @knowledge_base.id, id: params[:id]).first

    scope = if KnowledgeBase.granular_permissions?
              granular_scope [@category]
            else
              @category.self_with_children_answers
            end

    @answers = scope
      .localed(@locale)
      .sorted_by_internally_published
      .limit(ITEMS_IN_FEED)

    render :feed
  end

  private

  def granular_scope(category_filter = [])
    categories = KnowledgeBase::InternalAssets
      .new(effective_user, categories_filter: category_filter)
      .accessible_categories

    if categories.public_reader.none?
      return @knowledge_base.answers.where(category_id: categories.all)
    end

    answer_ids = granular_public_answers_ids(categories) + granular_internal_answers_ids(categories)

    @knowledge_base.answers.where(id: answer_ids)
  end

  def granular_public_answers_ids(categories)
    @knowledge_base.answers
      .where(category_id: categories.public_reader)
      .sorted_by_published
      .limit(ITEMS_IN_FEED)
      .pluck(:id)
  end

  def granular_internal_answers_ids(categories)
    @knowledge_base.answers
      .where(category_id: categories.internally_visible)
      .sorted_by_internally_published
      .limit(ITEMS_IN_FEED)
      .pluck(:id)
  end

  def effective_user
    return current_user if current_user.present?

    Token.check(action: 'KnowledgeBaseFeed', name: params[:token])
  end

  def ensure_response_format
    request.format = :atom
  end

  def fetch_knowledge_base
    @knowledge_base = KnowledgeBase.find params[:knowledge_base_id] || params[:id]
    @locale = Locale.find_by(locale: params[:locale])
  end

  def build_original_url(answer)
    translation = answer.translations.first

    help_answer_url(answer.category, translation, locale: translation.kb_locale.system_locale.locale)
  end

  def publishing_date(answer)
    [answer.published_at, answer.internal_at].compact.min
  end

  def updating_date(answer)
    [[answer.published_at, answer.internal_at].compact.min, answer.updated_at].compact.max
  end
end
