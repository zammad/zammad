# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared helpers for the knowledge base browsing queries: resolve the single
#   active knowledge base and the locale to render titles in. The resolved
#   locale is stored in the GraphQL context so the object types can localize
#   their `title` fields.
module Gql::Concerns::HandlesKnowledgeBaseLocale
  extend ActiveSupport::Concern

  private

  # Resolve an answer through the same availability rules as the knowledge base
  #   browse route. Record authorization is already handled declaratively by the
  #   GraphQL argument's `loads:` type; these additional rules are route- and
  #   locale-specific and therefore do not belong in AnswerPolicy.
  def resolve_browsable_knowledge_base_answer(answer, locale_code)
    # Only the active knowledge base is browsable, an answer loaded by GID included.
    knowledge_base = ::KnowledgeBase.active.first!

    store_knowledge_base_locale(knowledge_base, locale_code)

    visible = ::KnowledgeBase::Answer
      .visible_to_user(context.current_user, kb_locale: context[:knowledge_base_locale])
      .exists?(id: answer.id)

    raise Exceptions::Forbidden, "Answer #{answer.id} is not visible in the requested locale" if !visible

    answer
  end

  # The explicitly requested locale wins; otherwise fall back to the user's
  #   preferred locale (::KnowledgeBase::Locale.preferred already falls back to
  #   the primary/first locale). Authentication is required, so a user is present.
  def resolve_knowledge_base_locale(knowledge_base, locale_code)
    return if knowledge_base.nil?

    if locale_code.present?
      via_code = knowledge_base.kb_locales.joins(:system_locale).find_by(locales: { locale: locale_code })
      return via_code if via_code
    end

    ::KnowledgeBase::Locale.preferred(context.current_user, knowledge_base)
  end

  # Scoped to the current field's subtree, so aliased queries with different
  #   locales in one document cannot clobber each other.
  def store_knowledge_base_locale(knowledge_base, locale_code)
    context.scoped_set!(:knowledge_base_locale, resolve_knowledge_base_locale(knowledge_base, locale_code))
  end
end
