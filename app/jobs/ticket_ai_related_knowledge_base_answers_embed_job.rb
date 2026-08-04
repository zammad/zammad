# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Produces the ticket embedding the (synchronous) related-knowledge-base search needs and caches it,
# then pings the clients so they can run the search. The embedding_source tells the job what to embed:
#   :auto    - the ticket content, falling back to the summary when the content is too large
#   :summary - the ticket summary only (testing hook)
#
# Only a successful embedding is cached. Anything else (an error, or no embeddable content) is
# reported to the clients as a pushed error and never cached, so there is no failure state to poison
# the cache or to loop on.
class TicketAIRelatedKnowledgeBaseAnswersEmbedJob < AIJob
  include HasActiveJobLock

  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :dismiss_running

  def lock_key
    "#{self.class.name}/#{arguments[0].id}/#{Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache.version(arguments[0], arguments[2])}/#{arguments[1]}"
  end

  def perform(ticket, locale, embedding_source, current_user:)
    embedding = embedding_for_search(ticket, locale, current_user, embedding_source)

    if embedding
      Service::Ticket::AI::RelatedKnowledgeBaseAnswers::EmbeddingCache.store(ticket:, embedding_source:, locale:, embedding:)
      Service::Ticket::AI::RelatedKnowledgeBaseAnswers.broadcast_ping(ticket)
    else
      # No embeddable content (e.g. content too large and no summary available): nothing to search.
      Service::Ticket::AI::RelatedKnowledgeBaseAnswers.broadcast_error(ticket, __('The suggestions could not be generated.'))
    end
  rescue => e
    Rails.logger.error "Related knowledge base answers embedding failed for ticket #{ticket.id}: #{e.message}"
    Service::Ticket::AI::RelatedKnowledgeBaseAnswers.broadcast_error(ticket, e.message)
  end

  private

  def embedding_for_search(ticket, locale, current_user, embedding_source)
    return Service::AI::Ticket::EmbedSummary.with_current_user(current_user).execute(ticket:, locale:) if embedding_source == :summary

    # :auto - content by default, summary fallback when the content is too large
    Service::AI::Ticket::EmbedContent.execute(ticket:)
  rescue Service::AI::Ticket::EmbedContent::ContentTooLargeError
    Service::AI::Ticket::EmbedSummary.with_current_user(current_user).execute(ticket:, locale:)
  end
end
