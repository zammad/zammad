# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared helpers for the knowledge base browsing queries: resolve the single
#   active knowledge base and the locale to render titles in. The resolved
#   locale is stored in the GraphQL context so the object types can localize
#   their `title` fields.
module Gql::Concerns::HandlesKnowledgeBaseLocale
  extend ActiveSupport::Concern

  private

  def active_knowledge_base
    ::KnowledgeBase.active.first
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
