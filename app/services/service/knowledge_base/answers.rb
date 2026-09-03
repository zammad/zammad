# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the answers directly below a category that are visible to the current
#   user, in the category's `answer_sorting_mode` (or in the `sorting_mode` a caller
#   previews instead) — independent of the mode its subcategories are listed in. Visibility — including whether archived answers are
#   shown — is delegated to KnowledgeBase::Answer.visible_to_user: editors see
#   all answers in their categories (archived included), while non-editors only
#   see published/internal content, never archived.
#   Like the agent app, non-editors only see answers translated to the browsed
#   locale, while editors also see untranslated ones.
#   The relation is returned unpaginated for the GraphQL connection to page over.
class Service::KnowledgeBase::Answers < Service::Base
  attr_reader :category, :locale, :sorting_mode

  # `locale` is the resolved KnowledgeBase::Locale being browsed.
  #
  # `sorting_mode` overrides the category's stored `answer_sorting_mode` for this listing alone,
  #   which is what lets the sorting bar preview a mode before it is saved. One of
  #   KnowledgeBase::SORTING_MODES; nil (the normal case) lists in the stored mode.
  def initialize(category:, locale: nil, sorting_mode: nil)
    @category = category
    @locale = locale
    @sorting_mode = sorting_mode
  end

  def execute
    category
      .answers
      .visible_to_user(current_user, kb_locale: locale)
      # Unlike the category grid, this backs a GraphQL connection, so the order has to be in SQL —
      #   sorting a page in Ruby would page wrongly. `internal`, because this serves the agent
      #   interface; the public help site orders the same content through the same scope, but
      #   dates an answer by its publication alone (see KnowledgeBase::Public::BaseController).
      .sorted_by_mode(sorting_mode || category.answer_sorting_mode, system_locale_or_id: locale&.system_locale_id, internal: true)
      # Eager-load so AnswerType resolves title/translation_missing per page
      #   without a per-answer query (kb_locale drives the primary fallback).
      .includes(translations: :kb_locale)
  end
end
