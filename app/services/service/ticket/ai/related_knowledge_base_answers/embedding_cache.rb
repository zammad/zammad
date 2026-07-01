# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Caches the ticket embedding used by the related-knowledge-base search, shared between the
# synchronous gate (reads) and the embed job (writes). Keyed per ticket + version + embedding_source
# + locale, so a new (non-system) article, a different embedding source, or a different locale
# invalidates it. Locale matters because :auto can fall back to the (locale-specific) summary.
#
# Only successful embeddings are cached. Failures are never cached — the embed job reports them to
# the clients directly (a pushed error), so there is no failure sentinel to poison or loop on.
class Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache
  IDENTIFIER = 'ticket_related_knowledge_base_answers_embedding'.freeze

  class << self
    # The cached embedding (Array), or nil when nothing is cached for this version/source/locale yet.
    def lookup(ticket:, embedding_source:, locale:)
      AI::StoredResult
        .find_by(identifier: IDENTIFIER, related_object: ticket, locale: Locale.find_by(locale:), version: version(ticket, embedding_source))
        &.content&.fetch('embedding', nil)
    end

    def store(ticket:, embedding_source:, locale:, embedding:)
      AI::StoredResult
        .find_or_initialize_by(identifier: IDENTIFIER, related_object: ticket, locale: Locale.find_by(locale:))
        .update!(version: version(ticket, embedding_source), content: { 'embedding' => embedding })
    end

    def version(ticket, embedding_source)
      "#{ticket.articles.without_system_notifications.last&.created_at}/#{embedding_source}"
    end
  end
end
