# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the answers directly below a category that are visible to the current
#   user, sorted by position. Visibility — including whether archived answers are
#   shown — is delegated to KnowledgeBase::Answer.visible_to_user: editors see
#   all answers in their categories (archived included), while non-editors only
#   see published/internal content, never archived.
#   Like the agent app, non-editors only see answers translated to the browsed
#   locale, while editors also see untranslated ones.
#   The relation is returned unpaginated for the GraphQL connection to page over.
class Service::KnowledgeBase::Answers < Service::Base
  attr_reader :category, :locale

  # `locale` is the resolved KnowledgeBase::Locale being browsed.
  def initialize(category:, locale: nil)
    @category = category
    @locale = locale
  end

  def execute
    category
      .answers
      .visible_to_user(current_user, kb_locale: locale)
      .sorted
      # Eager-load so AnswerType resolves title/translation_missing per page
      #   without a per-answer query (kb_locale drives the primary fallback).
      .includes(translations: :kb_locale)
  end
end
