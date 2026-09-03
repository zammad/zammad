# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Resolves the `locale` argument of a knowledge base type's localized field. Every such field is
#   optional, so a caller asking for none shares the locale the query resolved
#   (`Gql::Concerns::HandlesKnowledgeBaseLocale`), which is what almost every caller does - hence
#   the fast path below.
#
# Including types name the knowledge base whose locales a code is looked up in, because they reach
#   it differently: `#locale_knowledge_base`.
module Gql::Types::Concerns::ResolvesKnowledgeBaseLocale
  extend ActiveSupport::Concern

  private

  # The locale the query itself resolved to, and the one every batch handed over through the
  #   context is keyed by.
  def query_locale
    context[:knowledge_base_locale]
  end

  def requested_locale(code)
    return query_locale if code.blank? || query_locale&.system_locale&.locale == code

    # Kept with `key?`, so a code that resolves to nothing is remembered as nothing: `||=` would
    #   look it up again for every localized field of every record in the response.
    cache = (context[:knowledge_base_locales_by_code] ||= {})
    return cache[code] if cache.key?(code)

    # A code this knowledge base has no locale for falls back to the locale the query resolved,
    #   which is the same fallback the query applies to its own argument
    #   (`Gql::Concerns::HandlesKnowledgeBaseLocale#resolve_knowledge_base_locale`). Clients pass
    #   one code to both, so answering `nil` here would mix the locale the query settled on with
    #   another locale's texts - and drop `currentLocale`, which the section entry redirects on.
    cache[code] = locale_by_code(code) || query_locale
  end

  def locale_by_code(code)
    locale_knowledge_base.kb_locales.joins(:system_locale).find_by(locales: { locale: code })
  end
end
